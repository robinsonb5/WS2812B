
#ifdef DEBUG
#include <stdio.h>
#include <string.h>
#include <malloc.h>
#else
#include "small_printf.h"
#include "uart.h"
#endif

// FIXME - use a smaller LFSR - this one will fail for RAMs smaller than 8 meg.
#define CYCLE_LFSR {lfsr<<=1; if(lfsr&0x400000) lfsr|=1; if(lfsr&0x200000) lfsr^=1;}


#define LFSR_SEED 12467


#define WS2812BASE 0xFFFFFFFC
#define HW_LED(x) *(volatile unsigned int *)(WS2812BASE+x)
#define REG_RGBLED 0


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


struct ripple ripr,ripg,ripb;
int lfsr;

int main(int argc, char **argv)
{
	int c,i;
	int d;

	ripple_clear(&ripr);
	ripple_clear(&ripg);
	ripple_clear(&ripb);

	lfsr=LFSR_SEED;
	c=0;

	d=lfsr&127;
	CYCLE_LFSR

	while(1)
	{
		if(d)
			--d;
		else
		{
			int r=lfsr&127;
			int r2;
			int h,rd,gn,bl;
			CYCLE_LFSR
			r2=1+(lfsr&63);
			if(r2>59)
				r2=59;

			// HSV
			// 00000-0ffff -> R constant, G rising, B zero
			// 10000-1ffff -> R falling, G constant, B zero
			// 20000-2ffff -> R zero, G constant, B rising
			// 30000-3ffff -> R zero, G falling, B constant
			// 40000-4ffff -> R rising, G zero, B constant
			// 50000-5ffff -> R constant, G zero, B falling
			// 60000-7ffff -> subtract 60000, multiply by 3

			h=lfsr&0x7ffff;
			if(h>0x5ffff)
				h=(h-0x60000)*3;

			if(h<0x10000)
			{
				rd=0xffff;
				gn=h;
				bl=0;
			}
			else if(h<0x20000)
			{
				rd=0x1ffff-h;
				gn=0xffff;
				bl=0;
			}
			else if(h<0x30000)
			{
				rd=0;
				gn=0xffff;
				bl=h-0x20000;
			}
			else if(h<0x40000)
			{
				rd=0;
				gn=0x3ffff-h;
				bl=0xffff;
			}
			else if(h<0x50000)
			{
				rd=h-0x40000;
				gn=0x0;
				bl=0xffff;
			}
			else if(h<0x60000)
			{
				rd=0xffff;
				gn=0;
				bl=0x5ffff-h;
			}

			ripr.rv[r2]+=rd;
			ripg.rv[r2]+=gn;
			ripb.rv[r2]+=bl;
			d=lfsr&255;
		}

		for(i=0;i<5000;++i)
			c=HW_UART(REG_UART);			
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

//			r=ripr.rv[i]>>8;
//			g=ripg.rv[i]>>8;
//			b=ripb.rv[i]>>8;
//			if(r<0)
//				r=-3-r;
//			if(g<0)
//				g=-3-g;
//			if(b<0)
//				b=-3-b;
//			if(r<0)
//				r=0;
//			if(g<0)
//				g=0;
//			if(b<0)
//				b=0;
			r&=255;
			g&=255;
			b&=255;
			HW_LED(REG_RGBLED)=(r<<16)|(g<<8)|b;
		}
		ripple_iteration(&ripr);
		ripple_iteration(&ripg);
		ripple_iteration(&ripb);
	}

	return(0);
}

