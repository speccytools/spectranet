LANG ?= en
localized_obj = $(if $(wildcard $(1)_$(LANG).asm),$(1)_$(LANG).o,$(1)_en.o)
ASOBJS = vectors.o init.o commands.o $(call localized_obj,string) memory.o chanmgr.o io.o buffer.o fileio.o ctrlchan.o flowcontrol.o
OUT = streams.module
# LIBS = -ldebug
include ../make.inc
