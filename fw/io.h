#ifndef IO_H
#define IO_H

#define WS2812BASE 0xFFFFFFFC
#define HW_LED(x) *(volatile unsigned int *)(WS2812BASE+x)
#define REG_RGBLED 0

#define IOBASE 0xFFFFFFF8
#define HW_IO(x) *(volatile unsigned int *)(IOBASE+x)
#define REG_SWITCHES 0

#endif

