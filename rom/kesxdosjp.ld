/* Page-B bridges merged into the final 256 bytes of ROM page 30. */
OUTPUT_FORMAT("binary")
OUTPUT_ARCH("z80")

MEMORY {
   modcall : ORIGIN = 0x2F00, LENGTH = 0x080
   chara   : ORIGIN = 0x2F80, LENGTH = 0x080
}

SECTIONS {
   .modcall : { *(.modcall) *(modcall) } > modcall
   .chara   : { *(.chara)   *(chara) } > chara
   .data    : { *(.data)    *(data) } > modcall
   .bss     : { *(.bss)     *(bss)  } > modcall
}
