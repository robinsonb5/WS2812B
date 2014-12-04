
#ifdef DEBUG
#include <stdio.h>
#include <string.h>
#include <malloc.h>
#else
#include "small_printf.h"
#include "uart.h"
#endif

#include "io.h"

// FIXME - use a smaller LFSR - this one will fail for RAMs smaller than 8 meg.
#define CYCLE_LFSR {lfsr<<=1; if(lfsr&0x400000) lfsr|=1; if(lfsr&0x200000) lfsr^=1;}


#define LFSR_SEED 12467


#define RIPPLE_SPRING 8
#define RIPPLE_NODES 62
#define RIPPLE_DAMP 15

struct ripple
{
	int rv[RIPPLE_NODES];
	int rvel[RIPPLE_NODES];
};


void ripple_clear(struct ripple *r)
{
	int i;
	for(i=0;i<RIPPLE_NODES;++i)
	{
		r->rv[i]=0;
		r->rvel[i]=0;
	}
}


void ripple_iteration(struct ripple *r)
{
	int i,j;
	int prev,prev2;
	for(i=1;i<RIPPLE_NODES-1;++i)
	{
		r->rv[i]+=r->rvel[i];
	}
	for(i=1;i<RIPPLE_NODES-1;++i)
	{
		int b=(0+2*r->rv[i-1]+3*r->rv[i]+2*r->rv[i+1])>>3;
		int acc=(RIPPLE_SPRING*(b-r->rv[i]));
		r->rvel[i]=(RIPPLE_DAMP*r->rvel[i])>>4;
		r->rvel[i]+=acc>>4;
	}
}


void scatter_iteration(struct ripple *r)
{
	int i,j;
	int prev,prev2;
	for(i=0;i<RIPPLE_NODES;++i)
	{
		if(r->rv[i]>128)
			r->rv[i]-=128;
		else
			r->rv[i]=0;
	}
}


void rain_iteration(struct ripple *r)
{
	int i,j;
	int prev,prev2;
	r->rv[0]=0;
	for(i=RIPPLE_NODES;i>0;--i)
	{
		int t=(r->rv[i]+r->rv[i-1])>>2;
		if(r->rv[i]<t)
			r->rv[i]=t;
		else if(r->rv[i]>256)
			r->rv[i]-=256;
		else
			r->rv[i]=0;
	}
}


void merge_iteration(struct ripple *r)
{
	int i,j;
	int prev,prev2;
	r->rv[0]=0;
	r->rv[RIPPLE_NODES]=0;
	for(i=1;i<RIPPLE_NODES-1;++i)
	{
		unsigned int j=28*r->rv[i]+r->rv[i-1]+r->rv[i+1];
		r->rv[i]=j>>5;
	}
}


struct ripple ripr,ripg,ripb;
int lfsr;
int rippledelay;


// Add a random spike of colour.
void hsvtorgb(int h,int *rd,int *gn,int *bl)
{
	// HSV
	// 00000-0ffff -> R constant, G rising, B zero
	// 10000-1ffff -> R falling, G constant, B zero
	// 20000-2ffff -> R zero, G constant, B rising
	// 30000-3ffff -> R zero, G falling, B constant
	// 40000-4ffff -> R rising, G zero, B constant
	// 50000-5ffff -> R constant, G zero, B falling
	// 60000-7ffff -> subtract 60000, multiply by 3

	if(h>0x5ffff)
		h=(h-0x60000)*3;

	if(h<0x10000)
	{
		*rd=0xffff;
		*gn=h;
		*bl=0;
	}
	else if(h<0x20000)
	{
		*rd=0x1ffff-h;
		*gn=0xffff;
		*bl=0;
	}
	else if(h<0x30000)
	{
		*rd=0;
		*gn=0xffff;
		*bl=h-0x20000;
	}
	else if(h<0x40000)
	{
		*rd=0;
		*gn=0x3ffff-h;
		*bl=0xffff;
	}
	else if(h<0x50000)
	{
		*rd=h-0x40000;
		*gn=0x0;
		*bl=0xffff;
	}
	else if(h<0x60000)
	{
		*rd=0xffff;
		*gn=0;
		*bl=0x5ffff-h;
	}
}


static int redt,greent,bluet;
void add_hsv(int h,int v)
{
	int r2;
	CYCLE_LFSR
	r2=1+(lfsr&63);
	if(r2>59)
		r2=59;
	hsvtorgb(h,&redt,&greent,&bluet);
	ripr.rv[r2]+=(v*redt)>>8;
	ripg.rv[r2]+=(v*greent)>>8;
	ripb.rv[r2]+=(v*bluet)>>8;
}


void add_rgb()
{
	int h;
	h=lfsr&0x7ffff;
	add_hsv(h,256);
}


void ripple_update()
{
	int i;

	if(rippledelay)
		--rippledelay;
	else
	{
		add_rgb();
		rippledelay=lfsr&255;
	}
	for(i=1;i<61;++i)
	{
		int r=0,g=0,b=0;
		int acc,base;

		if(ripr.rvel[i]<0)
			r=-ripr.rvel[i];
		else
			r=ripr.rvel[i];

		if(ripg.rvel[i]<0)
			g=-ripg.rvel[i];
		else
			g=ripg.rvel[i];

		if(ripb.rvel[i]<0)
			b=-ripb.rvel[i];
		else
			b=ripb.rvel[i];

		base=(0+2*ripr.rv[i-1]+3*ripr.rv[i]+2*ripr.rv[i+1])>>3;
		acc=(RIPPLE_SPRING*(base-ripr.rv[i]));

		if(acc<0)
			r-=acc;
		else
			r+=acc;

		base=(0+2*ripg.rv[i-1]+3*ripg.rv[i]+2*ripg.rv[i+1])>>3;
		acc=(RIPPLE_SPRING*(base-ripg.rv[i]));

		if(acc<0)
			g-=acc;
		else
			g+=acc;

		base=(0+2*ripb.rv[i-1]+3*ripb.rv[i]+2*ripb.rv[i+1])>>3;
		acc=(RIPPLE_SPRING*(base-ripb.rv[i]));

		if(acc<0)
			b-=acc;
		else
			b+=acc;

		r>>=8;
		g>>=8;
		b>>=8;

		r&=255;
		g&=255;
		b&=255;
		HW_LED(REG_RGBLED)=(r<<16)|(g<<8)|b;
	}
	ripple_iteration(&ripr);
	ripple_iteration(&ripg);
	ripple_iteration(&ripb);
}


void upload_simple(int ro,int go,int bo)
{
	int i;
	for(i=1;i<61;++i)
	{
		int r=0,g=0,b=0;
		int acc,base;

		r=ripr.rv[i];
		g=ripg.rv[i];
		b=ripb.rv[i];

		r>>=8;
		g>>=8;
		b>>=8;

		r+=ro;
		if(r>255) r=255;
		g+=go;
		if(g>255) g=255;
		b+=bo;
		if(b>255) b=255;

		HW_LED(REG_RGBLED)=(r<<16)|(g<<8)|b;
	}
}


void scatter_update()
{
	int i;

	if(rippledelay)
		--rippledelay;
	else
	{
		add_rgb();
		rippledelay=lfsr&63;
	}
	upload_simple(0,0,0);
	scatter_iteration(&ripr);
	scatter_iteration(&ripg);
	scatter_iteration(&ripb);
}

void merge_update()
{
	int i;

	if(rippledelay)
		--rippledelay;
	else
	{
		add_rgb();
		rippledelay=lfsr&255;
	}
	upload_simple(0,0,0);
	merge_iteration(&ripr);
	merge_iteration(&ripg);
	merge_iteration(&ripb);
}


void rain_update()
{
	int i;

	if(rippledelay)
		--rippledelay;
	else
	{
		add_rgb();
		rippledelay=lfsr&63;
	}
	upload_simple(0,0,0);
	rain_iteration(&ripr);
	rain_iteration(&ripg);
	rain_iteration(&ripb);
}


void fire_update()
{
	int h;
	int i;

	if(rippledelay)
		--rippledelay;
	else
	{
		h=lfsr&0x7fff;
		add_hsv(h+0x3fff,lfsr&255);
		CYCLE_LFSR
		rippledelay=lfsr&127;
	}
	h=lfsr&0x3fff;
	hsvtorgb(h+0x1fff,&redt,&greent,&bluet);
	CYCLE_LFSR
	i=24+lfsr&7;
	upload_simple((redt*i)>>16,(greent*i)>>16,(bluet*i)>>16);
	merge_iteration(&ripr);
	merge_iteration(&ripg);
	merge_iteration(&ripb);
}


int main(int argc, char **argv)
{
	int c,i;

	rippledelay=1;
	ripple_clear(&ripr);
	ripple_clear(&ripg);
	ripple_clear(&ripb);

	lfsr=LFSR_SEED;
	c=0;

	CYCLE_LFSR

	while(1)
	{
		int sw=HW_IO(REG_SWITCHES);

		switch(sw>>4)
		{
			case 0:
				ripple_update();
				break;
			case 1:
				scatter_update();
				break;
			case 2:
				merge_update();
				break;
			case 3:
				fire_update();
				break;
			case 4:
				rain_update();
				break;
			default:
				break;
		}

		for(i=0;i<5000;++i)
			c=HW_UART(REG_UART);			
	}

	return(0);
}

