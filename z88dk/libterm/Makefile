# Makefile to build the libterm library (Z80 terminal stdout via port decode 0x043B)
PLIBNAME = libterm
PASMFILES = libterm.lst

all: libterm.lib

libterm.lib: $(PASMFILES) fputc_cons_native.asm
	$(ASSEMBLER) $(ASMFLAGS) -x$(PLIBNAME) @$(PASMFILES)

install: libterm.lib
	$(CP) *.lib $(ZCCCFG)/../clibs
	-[ -d ./include ] && $(CP) -r ./include $(ZCCCFG)/../..

include ../make.inc
