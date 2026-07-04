LANG ?= en
localized_obj = $(if $(wildcard $(1)_$(LANG).asm),$(1)_$(LANG).o,$(1)_en.o)
ASOBJS = getmsg.o $(call localized_obj,messages) vectors.o
OUT = msgrom.module
include ../make.inc
