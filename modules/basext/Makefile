LANG ?= en
localized_obj = $(if $(wildcard $(1)_$(LANG).asm),$(1)_$(LANG).o,$(1)_en.o)
ASOBJS = boot.o commands.o info.o init.o listdir.o loader.o $(call localized_obj,strings) tapetrap.o vectors.o copy.o basename.o move.o
OUT = basext.module
include ../make.inc
