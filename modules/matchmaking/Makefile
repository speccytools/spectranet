ASOBJS = matchmaking.o save7ffd.o
OUT = matchmaking.module
ASFLAGS = -I../../include -I../../rom
include ../make.inc
ASFLAGS += -I../../rom

matchmaking.o: ../../rom/page1.xinc

# Display takeover belongs to this module, including Spectrum paging detection.
save7ffd.o: ../../rom/save7ffd.asm
	$(AS) $(ASFLAGS) $< -o $@
