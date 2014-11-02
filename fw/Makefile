BASE	= zpu-elf
CC      = $(BASE)-gcc
LD      = $(BASE)-gcc
AS      = $(BASE)-as
CP      = $(BASE)-objcopy
DUMP    = $(BASE)-objdump

# we use mincrt0.s from here
STARTUP_DIR = ../ZPUFlex/Firmware/startup

# we fetch ROM prologue / epilogue from here
RTL_DIR = ../ZPUFlex/RTL/

# we use registers and small_printf from here
UTIL_DIR = ../ZPUFlex/Firmware/util

BUILD_DIR=zpu_obj

MINSTARTUP_SRC = $(STARTUP_DIR)/mincrt0.s $(STARTUP_DIR)/premain.s
MINSTARTUP_OBJ = $(patsubst $(STARTUP_DIR)/%.s,$(BUILD_DIR)/%.o,$(MINSTARTUP_SRC))

COMMON_SRC = $(UTIL_DIR)/uart.c $(UTIL_DIR)/small_printf.c
COMMON_OBJ = $(patsubst $(UTIL_DIR)/%.c,$(BUILD_DIR)/%.o,$(COMMON_SRC))

BOOT_PRJ = WS2812B
BOOT_SRC = main.c
BOOT_OBJ = $(COMMON_OBJ) $(patsubst %.c,$(BUILD_DIR)/%.o,$(BOOT_SRC))

LINKMAP  = ../ZPUFlex/Firmware/boot_standalone_remapped.ld
LIBDIR   = 

# Commandline options for each tool.

ZPUOPTS= -mno-poppcrel -mno-pushspadd -mno-callpcrel -mno-byteop -mno-neg # No-neg requires bugfixed toolchain

CFLAGS  = -I. -I$(UTIL_DIR)/ -c -Os $(ZPUOPTS) -DPRINTF_HEX_ONLY -g
# -DDISABLE_UART_TX 
AFLAGS  = 
LFLAGS  = -nostartfiles -Wl,--relax -nostdlib -Os -g
CP_HEXFLAGS = -Oihex
CP_SRECFLAGS = -Osrec --gap-fill 0

# Libraries.
LIBS       =

# Our target.
all: $(BUILD_DIR) $(BOOT_PRJ).bin $(BOOT_PRJ).mif $(BOOT_PRJ)_ROM.vhd $(BOOT_PRJ).rpt

mif: $(BOOT_PRJ).mif

clean:
	rm -f $(BUILD_DIR)/*.o *.hex *.elf *.map *.lst *.srec $(BOOT_PRJ).mif $(BOOT_PRJ).rom *~ */*.o *.bin

link:
	rm -f $(BOOT_PRJ).mif $(BOOT_PRJ).elf
	make

# Convert ELF binary to bin file.
%.bin: %.elf
	$(CP) -O binary $< $@

# Convert ELF binary to Intel HEX file.
%.hex: %.elf
	$(CP) $(CPFLAGS) $< $@

# Convert ELF binary to SREC file
%.srec: %.elf
	$(CP) $(CP_SRECFLAGS) $< $@

# Convert SREC to .mif file
%.mif: %.srec
	srec_cat $< -offset=-0x04000000 -o $@ -mif 32

%.rpt: %.elf
	echo >$@ -n "End of code:\t"
	$(DUMP) -x $< | grep >>$@ _romend
	echo >>$@ -n "Start of BSS:\t"
	$(DUMP) -x $< | grep  >>$@ __bss_start__
	echo >>$@ -n "End of BSS:\t"
	$(DUMP) -x $< | grep >>$@ __bss_end__
	cat $@

zpuromgen: ../ZPUFlex/Firmware/zpuromgen.c
	gcc -o zpuromgen ../ZPUFlex/Firmware/zpuromgen.c

%_ROM.vhd: %.bin zpuromgen
	sed 's/dualportram/$*_ROM/' >$*_ROM.vhd <$(RTL_DIR)/rom_prologue.vhd
	./zpuromgen $*.bin >>$*_ROM.vhd
	cat >>$*_ROM.vhd $(RTL_DIR)/rom_epilogue.vhd

# Link - this produces an ELF binary.

$(BOOT_PRJ).elf: $(MINSTARTUP_OBJ) $(BOOT_OBJ)
	$(LD) $(LFLAGS) -T $(LINKMAP) -o $@ $+ $(LIBS)

$(BUILD_DIR)/%.o: %.c Makefile
	$(CC) $(CFLAGS)  -o $@ -c $<

$(BUILD_DIR)/%.o: $(UTIL_DIR)/%.c
	$(CC) $(CFLAGS)  -o $@ -c $<

$(BUILD_DIR)/%.o: %.s
	$(AS) -o $@ $<

$(BUILD_DIR)/%.o: $(STARTUP_DIR)/%.s
	$(AS) -o $@ $<

$(BUILD_DIR):
	mkdir $(BUILD_DIR)

