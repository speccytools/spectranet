/* Dot-command esxDOS kernel: a section-0 ROM page with the required RSTs. */
OUTPUT_FORMAT("binary")
OUTPUT_ARCH("z80")

MEMORY {
   isr    : ORIGIN = 0x0038, LENGTH = 0x0003
   kernel : ORIGIN = 0x0080, LENGTH = 0x0f80
   rst0   : ORIGIN = 0x0000, LENGTH = 0x0008
   rst8   : ORIGIN = 0x0008, LENGTH = 0x0008
   rst10  : ORIGIN = 0x0010, LENGTH = 0x0008
   rst18  : ORIGIN = 0x0018, LENGTH = 0x0008
   rst20  : ORIGIN = 0x0020, LENGTH = 0x0008
}

SECTIONS {
   .rst0 : {
      *(.rst0)
      *(rst0)
   } > rst0
   .rst8 : {
      *(.rst8)
      *(rst8)
   } > rst8
   .rst10 : {
      *(.rst10)
      *(rst10)
   } > rst10
   .rst18 : {
      *(.rst18)
      *(rst18)
   } > rst18
   .rst20 : {
      *(.rst20)
      *(rst20)
   } > rst20
   .isr : {
      *(.isr)
      *(isr)
   } > isr
   .text : {
      *(.text)
      *(text)
   } > kernel
   .data : {
      *(.data)
      *(data)
   } > kernel
   .bss : {
      *(.bss)
      *(bss)
   } > kernel
}
