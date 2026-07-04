LANG ?= en
localized_obj = $(if $(wildcard $(1)_$(LANG).asm),$(1)_$(LANG).o,$(1)_en.o)
ASOBJS = directory.o inputloop.o loadsna.o memory.o savesna.o screen.o $(call localized_obj,strings) utils.o vectors.o
OUT = snapman.module
include ../make.inc
