
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
#define RIPPLE_NODES 152
#define RIPPLE_DAMP 15

int lfsr;
int rippledelay;

struct ripple
{
	int rv[RIPPLE_NODES];
	int rvel[RIPPLE_NODES];
};


struct rgbripple
{
	int ro,go,bo;
	struct ripple ripr;
	struct ripple ripg;
	struct ripple ripb;
};


struct LightEffect
{
	void (*Clear)(struct LightEffect *this,struct rgbripple *r);
	void (*Iteration)(struct LightEffect *this,struct ripple *r);
	void (*RGBIteration)(struct LightEffect *this,struct rgbripple *r);
	void (*Update)(struct LightEffect *this,struct rgbripple *r);
	void (*Send)(struct LightEffect *this,struct rgbripple *r);
	void (*Add)(struct LightEffect *this,struct rgbripple *r);
	int delaymask;
};

struct rgbripple ripples;



// Generic routines applicable to most effects.

void simple_upload(struct LightEffect *this,struct rgbripple *rgb)
{
	int i;
	for(i=1;i<RIPPLE_NODES-1;++i)
	{
		int r=0,g=0,b=0;
		int acc,base;

		r=rgb->ripr.rv[i];
		g=rgb->ripg.rv[i];
		b=rgb->ripb.rv[i];

		r>>=8;
		g>>=8;
		b>>=8;

		r+=rgb->ro;
		if(r>255) r=255;
		g+=rgb->go;
		if(g>255) g=255;
		b+=rgb->bo;
		if(b>255) b=255;

		HW_LED(REG_RGBLED)=(r<<16)|(g<<8)|b;
	}
}


void simple_rgbiteration(struct LightEffect *this,struct rgbripple *rgb)
{
	this->Iteration(this,&rgb->ripr);
	this->Iteration(this,&rgb->ripg);
	this->Iteration(this,&rgb->ripb);
}


void simple_clear(struct LightEffect *this,struct rgbripple *rgb)
{
	int i;
	for(i=0;i<RIPPLE_NODES;++i)
	{
		rgb->ripr.rv[i]=0;
		rgb->ripr.rvel[i]=0;
		rgb->ripg.rv[i]=0;
		rgb->ripg.rvel[i]=0;
		rgb->ripb.rv[i]=0;
		rgb->ripb.rvel[i]=0;
	}
	rgb->ro=0;
	rgb->go=0;
	rgb->bo=0;
}


void simple_update(struct LightEffect *this,struct rgbripple *rgb)
{
	int h;
	int i;

	if(rippledelay)
		--rippledelay;
	else
	{
		this->Add(this,rgb);
		CYCLE_LFSR
		rippledelay=lfsr&this->delaymask;
	}
	this->RGBIteration(this,rgb);
}



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
void add_hsv(struct rgbripple *rgb,int h,int v)
{
	int r2;
	CYCLE_LFSR
	r2=(lfsr&255);
	while(r2>150)
		r2-=150;
	++r2;
	hsvtorgb(h,&redt,&greent,&bluet);
	rgb->ripr.rv[r2]+=(v*redt)>>8;
	rgb->ripg.rv[r2]+=(v*greent)>>8;
	rgb->ripb.rv[r2]+=(v*bluet)>>8;
}


void add_rgb(struct LightEffect *this,struct rgbripple *rgb)
{
	int h;
	h=lfsr&0x7ffff;
	add_hsv(rgb,h,256);
}



// Colour ripple effect

void ripple_upload(struct LightEffect *this,struct rgbripple *rgb)
{
	int i;
	for(i=1;i<RIPPLE_NODES-1;++i)
	{
		int r=0,g=0,b=0;
		int acc,base;

		if(rgb->ripr.rvel[i]<0)

			r=-rgb->ripr.rvel[i];
		else
			r=rgb->ripr.rvel[i];

		if(rgb->ripg.rvel[i]<0)
			g=-rgb->ripg.rvel[i];
		else
			g=rgb->ripg.rvel[i];

		if(rgb->ripb.rvel[i]<0)
			b=-rgb->ripb.rvel[i];
		else
			b=rgb->ripb.rvel[i];

		base=(0+2*rgb->ripr.rv[i-1]+3*rgb->ripr.rv[i]+2*rgb->ripr.rv[i+1])>>3;
		acc=(RIPPLE_SPRING*(base-rgb->ripr.rv[i]));

		if(acc<0)
			r-=acc;
		else
			r+=acc;

		base=(0+2*rgb->ripg.rv[i-1]+3*rgb->ripg.rv[i]+2*rgb->ripg.rv[i+1])>>3;
		acc=(RIPPLE_SPRING*(base-rgb->ripg.rv[i]));

		if(acc<0)
			g-=acc;
		else
			g+=acc;

		base=(0+2*rgb->ripb.rv[i-1]+3*rgb->ripb.rv[i]+2*rgb->ripb.rv[i+1])>>3;
		acc=(RIPPLE_SPRING*(base-rgb->ripb.rv[i]));

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
}


void ripple_iteration(struct LightEffect *this,struct ripple *r)
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


const struct LightEffect RippleEffect=
{
	simple_clear,
	ripple_iteration,
	simple_rgbiteration,
	simple_update,
	ripple_upload,
	add_rgb,
	255
};



// Scatter effect

void scatter_iteration(struct LightEffect *this,struct ripple *r)
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


const struct LightEffect ScatterEffect=
{
	simple_clear,
	scatter_iteration,
	simple_rgbiteration,
	simple_update,
	simple_upload,
	add_rgb,
	63
};



// Rain effect

void rain_iteration(struct LightEffect *this,struct ripple *r)
{
	int i,j;
	int prev,prev2;
	r->rv[0]=0;
	for(i=RIPPLE_NODES;i>0;--i)
	{
		int t=r->rv[i-1];
		if(r->rv[i]<(t-128))
			r->rv[i]=t+128;
		else if(r->rv[i]>512)
			r->rv[i]-=512;
		else
			r->rv[i]=0;
	}
}


void rain_add(struct LightEffect *this,struct rgbripple *rgb)
{
	int h=lfsr&0x1ffff;
	add_hsv(rgb,h+0x24000,lfsr&255);
}


const struct LightEffect RainEffect=
{
	simple_clear,
	rain_iteration,
	simple_rgbiteration,
	simple_update,
	simple_upload,
	rain_add,
	63
};



// Merge effect


void merge_iteration(struct LightEffect *this,struct ripple *r)
{
	int i,j;
	int prev,prev2;
	r->rv[0]=0;
	r->rv[RIPPLE_NODES]=0;
	for(i=1;i<RIPPLE_NODES-1;++i)
	{
		unsigned int j=61*r->rv[i]+r->rv[i-1]+r->rv[i+1];
		r->rv[i]=j>>6;
	}
}

const struct LightEffect MergeEffect=
{
	simple_clear,
	merge_iteration,
	simple_rgbiteration,
	simple_update,
	simple_upload,
	add_rgb,
	63
};


// Fire effect


void fire_background(struct ripple *r)
{
	int i;
	unsigned int j;
	unsigned int h1,h2,h3;
	j=r->rvel[0]+r->rvel[1]+r->rvel[2]+r->rvel[3];
	h1=r->rvel[0];
	h2=r->rvel[1];
	for(i=2;i<RIPPLE_NODES-2;++i)
	{
		h3=r->rvel[i];
		j+=r->rvel[i+2];
		r->rvel[i]=(j*52)>>8;
		j-=h1;
		h1=h2;
		h2=h3;
	}	
}


void fire_clear(struct LightEffect *this,struct rgbripple *rgb)
{
	int i,j,h;
	simple_clear(this,rgb);

	// Set random background colours
	for(i=0;i<RIPPLE_NODES;++i)
	{
		h=lfsr&0x3fff;
		hsvtorgb(h+0x1fff,&redt,&greent,&bluet);
		CYCLE_LFSR
		j=64+lfsr&15;
		rgb->ripr.rvel[i]=(redt*j)>>16;
		rgb->ripg.rvel[i]=(greent*j)>>16;
		rgb->ripb.rvel[i]=(bluet*j)>>16;
	}
	fire_background(&rgb->ripr);
	fire_background(&rgb->ripg);
	fire_background(&rgb->ripb);
}


void fire_rgbiteration(struct LightEffect *this,struct rgbripple *rgb)
{
	int i,h;
	this->Iteration(this,&rgb->ripr);
	this->Iteration(this,&rgb->ripg);
	this->Iteration(this,&rgb->ripb);

	// Background colour
	h=lfsr&0x3fff;
	hsvtorgb(h+0x1fff,&redt,&greent,&bluet);
	CYCLE_LFSR
	i=64+lfsr&15;
	// Pick one node at random each frame.
	CYCLE_LFSR;
	h=lfsr&255;
	while(h>RIPPLE_NODES-5)
		h-=RIPPLE_NODES-5;
	rgb->ripr.rvel[h+2]=(redt*i)>>16;
	rgb->ripg.rvel[h+2]=(greent*i)>>16;
	rgb->ripb.rvel[h+2]=(bluet*i)>>16;
	fire_background(&rgb->ripr);
	fire_background(&rgb->ripg);
	fire_background(&rgb->ripb);
}

void fire_add(struct LightEffect *this,struct rgbripple *rgb)
{
	int h=lfsr&0x7fff;
	add_hsv(rgb,h+0x3fff,lfsr&255);
	CYCLE_LFSR
	rippledelay=lfsr&127;
}


void fire_upload(struct LightEffect *this,struct rgbripple *rgb)
{
	int i;
	for(i=1;i<RIPPLE_NODES-1;++i)
	{
		int r=0,g=0,b=0;
		int acc,base;

		r=rgb->ripr.rv[i];
		g=rgb->ripg.rv[i];
		b=rgb->ripb.rv[i];

		r>>=8;
		g>>=8;
		b>>=8;

		r+=rgb->ripr.rvel[i];
		if(r>255) r=255;
		g+=rgb->ripg.rvel[i];
		if(g>255) g=255;
		b+=rgb->ripb.rvel[i];;
		if(b>255) b=255;

		HW_LED(REG_RGBLED)=(r<<16)|(g<<8)|b;
	}
}


const struct LightEffect FireEffect=
{
	fire_clear,
	merge_iteration,
	fire_rgbiteration,
	simple_update,
	fire_upload,
	fire_add,
	63
};


// Fire and Ice


const struct LightEffect FireAndIceEffect=
{
	fire_clear,
	merge_iteration,
	fire_rgbiteration,
	simple_update,
	fire_upload,
	rain_add,
	63
};


int main(int argc, char **argv)
{
	int c,i;
	int prevsw;

	rippledelay=1;
	struct LightEffect *effect=&RippleEffect;
	effect->Clear(effect,&ripples);

	lfsr=LFSR_SEED;
	c=0;

	CYCLE_LFSR
	prevsw=-1;
	while(1)
	{
		int sw=HW_IO(REG_SWITCHES);
		if(sw!=prevsw)
		{
			switch(sw>>4)
			{
				case 0:
					effect=&RippleEffect;
					break;
				case 1:
					effect=&ScatterEffect;
					break;
				case 2:
					effect=&MergeEffect;
					break;
				case 3:
					effect=&FireEffect;
					break;
				case 4:
					effect=&RainEffect;
					break;
				case 5:
					effect=&FireAndIceEffect;
					break;
				default:
					break;
			}
			prevsw=sw;
			effect->Clear(effect,&ripples);
		}
		effect->Update(effect,&ripples);
		effect->Send(effect,&ripples);

		for(i=0;i<2500;++i)
			c=HW_UART(REG_UART);			
	}

	return(0);
}

