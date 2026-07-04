LANG ?= en
localized_obj = $(if $(wildcard $(1)_$(LANG).asm),$(1)_$(LANG).o,$(1)_en.o)
ASOBJS = configbasic.o configdata.o fs_config_ui.o $(call localized_obj,fs_strings) gen_copycfg.o if_config_ui.o if_configmain.o if_saveconfig.o $(call localized_obj,if_strings) init.o vectors.o
TESTOBJS = cfgtest.o configdata.o
CREATEOBJS = create.o
LIBS = -lromui
LIBPATH = -L ../../syslib
FLOBJS = flashwrite.o
FLLDFLAGS = -T flashwrite.ld $(LIBPATH) -Map $(FLMAP)
FLLIBS = -lflashwrite
FLOUT = flashwrite.bin
FLMAP = $(FLOUT).map
DUMPOBJS = dumpconfig.o
DUMPOUT = dumpconfig.bin
DUMPLDFLAGS = -T standalone.ld
SAOBJS = standalone_ifconfig.o gen_copycfg.o if_config_ui.o $(call localized_obj,if_strings) sa_if_saveconfig.o sa_flashwrite.o 
SAOUT = ifconfig.bin
SALDFLAGS = -T standalone.ld $(LIBPATH)
SALIBS = -lflashwrite -lromui
OUT = config.module
TESTOUT = cfgtest.bin
CREATEOUT = create.bin

all:	flash module dumpcfg standalone
include ../make.inc

flash:	$(FLOBJS)
	$(LD) -o $(FLOUT) $(FLOBJS) $(FLLDFLAGS) $(FLLIBS)

dumpcfg:	$(DUMPOBJS)
	$(LD) -o $(DUMPOUT) $(DUMPOBJS) $(DUMPLDFLAGS)

standalone:	$(SAOBJS)
	$(LD) -o $(SAOUT) $(SAOBJS) $(SALDFLAGS) $(SALIBS)
