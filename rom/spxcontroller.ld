OUTPUT_FORMAT("binary")
OUTPUT_ARCH("z80")
MEMORY {
    controller : ORIGIN = 0x2000, LENGTH = 0x0800
}
SECTIONS
{
    .text : { *(.text) *(text) } > controller
    .data : { *(.data) *(data) } > controller
    .bss : { *(.bss) *(bss) } > controller
}
