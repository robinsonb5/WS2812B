
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


#define RIPPLE_SPRING 4
#define RIPPLE_NODES 62
#define RIPPLE_DAMP 15

struct ripple
{
	int rv[RIPPLE_NODES];
	int rvel[RIPPLE_NODES];
	int rspread[RIPPLE_NODES];
};


void ripple_clear(struct ripple *r)
{
	int i;
	for(i=0;i<RIPPLE_NODES;++i)
	{
		r->rv[i]=0;
		r->rvel[i]=0;
		r->rspread[i]=0;
	}
}


void ripple_iteration(struct ripple *r)
{
	int i,j;
	for(i=1;i<RIPPLE_NODES-1;++i)
	{
		int b=(r->rv[i-1]+r->rv[i]+r->rv[i]+r->rv[i+1])>>2;
		int acc=(RIPPLE_SPRING*(b-r->rv[i]));
		r->rvel[i]=(RIPPLE_DAMP*r->rvel[i])>>4;
		r->rvel[i]+=acc>>4;
	}
	for(i=1;i<RIPPLE_NODES-1;++i)
	{
		r->rv[i]+=r->rvel[i];
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
			CYCLE_LFSR
			if(r<58)
				ripr.rv[r+1]=65535;
			else if(r<116)
				ripg.rv[r-57]=65535;
			else
			{
				r=lfsr&63;
				if(r>58)
					r=58;
				ripb.rv[1+r]=65535;
			}
			d=32+lfsr&127;
		}

		for(i=0;i<4096;++i)
			c=HW_UART(REG_UART);			
		for(i=1;i<61;++i)
		{
			int r,g,b;
			r=ripr.rv[i]>>8;
			g=ripg.rv[i]>>8;
			b=ripb.rv[i]>>8;
			if(r<0)
				r=-r;
			if(g<0)
				g=-g;
			if(b<0)
				b=-b;
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

