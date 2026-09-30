/* Spectranet modules LD script */
OUTPUT_FORMAT("binary")
OUTPUT_ARCH("z80")
MEMORY {
   /*
    * DivMMC automaps on M1 fetches at 0x04C6, 0x04D7, 0x0562 and
    * 0x056A. Keep the 0x04xx addresses inside linker-owned JP operands and
    * jump across the 0x05xx addresses, so ordinary page-zero code can never
    * execute there. The executable
    * regions are allocation buckets only; they carry no subsystem meaning.
    */
   pagez0 : ORIGIN = 0x007D, LENGTH = 0x0447
   divmmc04c6 : ORIGIN = 0x04C4, LENGTH = 0x0003
   pagez1 : ORIGIN = 0x04C7, LENGTH = 0x000E
   divmmc04d7 : ORIGIN = 0x04D5, LENGTH = 0x0003
   pagez2 : ORIGIN = 0x04D8, LENGTH = 0x0084
   ldbytes055c : ORIGIN = 0x055C, LENGTH = 0x0003
   divmmctape : ORIGIN = 0x055F, LENGTH = 0x000C
   pagez4 : ORIGIN = 0x056B, LENGTH = 0x0A95
   rst0 : ORIGIN = 0x0000, LENGTH = 0x0008
   rst8 : ORIGIN = 0x0008, LENGTH = 0x0008
   rst10 : ORIGIN = 0x0010, LENGTH = 0x0018
   rst28 : ORIGIN = 0x0028, LENGTH = 0x0008
   rst30 : ORIGIN = 0x0030, LENGTH = 0x0008
   isr : ORIGIN = 0x0038, LENGTH = 0x0020
   esxdosreject : ORIGIN = 0x0058, LENGTH = 0x000E
   nmi : ORIGIN = 0x0066, LENGTH = 0x0014
   unpage : ORIGIN = 0x007B, LENGTH = 0x0002
}
SECTIONS
{
.rst0 : {
	*(.rst0)
	*(rst0)
	__Hrst0 = .;
	} > rst0
.rst8 : {
	*(.rst8)
	*(rst8)
	__Hrst8 = .;
	} > rst8
.rst10 : {
	*(.rst10)
	*(rst10)
	__Hrst10 = .;
	} > rst10
.rst28 : {
	*(.rst28)
	*(rst28)
	__Hrst28 = .;
	} > rst28
.rst30 : {
	*(.rst30)
	*(rst30)
	__Hrst30 = .;
	} > rst30
.isr : {
	*(.isr)
	*(isr)
	__Hisr = .;
	} > isr
.esxrej : {
	*(.esxrej)
	*(esxrej)
	__Hesxdosreject = .;
	} > esxdosreject
.nmi : {
	*(.nmi)
	*(nmi)
	__Hnmi = .;
	} > nmi
.unpage : {
	*(.unpage)
	*(unpage)
	__Hunpage = .;
	} > unpage
.textz0 : {
        /* Keep whole input sections on one side of each forbidden address. */
        zeropage.o(.text)
        reset.o(.text)
        trapdispatch.o(.text)
        w5100_ifconfig.o(.text)
        w5100_buffer.o(.text)
        dns.o(.text)
        } > pagez0
.divmmc04c6 : {
        /* JP 0x04C7: 0x04C6 is the high-byte operand, never an M1 fetch. */
        BYTE(0xC3)
        SHORT(ORIGIN(pagez1))
        } > divmmc04c6
.textz1 : {
        /* Deferred BASIC border setup fits between the first two guards. */
        *(.defcolor)
        *(defcolor)
        } > pagez1
.divmmc04d7 : {
        /* JP 0x04D8: 0x04D7 is the high-byte operand, never an M1 fetch. */
        BYTE(0xC3)
        SHORT(ORIGIN(pagez2))
        } > divmmc04d7
.textz2 : {
        /* Whole helper section moved here to balance the guarded buckets. */
        w5100_genintfunc.o(.text)
        *(.spxgate)
        *(spxgate)
        } > pagez2
.ldbytes055c : {
        *(.ldtrap)
        *(ldtrap)
        } > ldbytes055c
.divmmctape : {
        /* The $055C JP skips this range, including both Next tape traps. */
        . = ORIGIN(divmmctape) + LENGTH(divmmctape);
        } > divmmctape = 0x00
.textz4 : {
        /* All unallocated and future page-zero code lands in the final zone. */
        *(.defpaper)
        *(defpaper)
        *(.text)
        *(text)
         __Htext = .;
        } > pagez4
.data : {
         __Ldata = .;
        *(.data)
        *(data)
         __Hdata = .;
        } > pagez4
.bss :  {
         __Lbss = .;
        *(.bss)
        *(bss)
         __Hbss = .;
        } > pagez4

ASSERT(ADDR(.divmmc04c6) == 0x04C4,
       "DivMMC 0x04C6 guard moved")
ASSERT(SIZEOF(.divmmc04c6) == 3,
       "DivMMC 0x04C6 guard has the wrong size")
ASSERT(ADDR(.divmmc04d7) == 0x04D5,
       "DivMMC 0x04D7 guard moved")
ASSERT(SIZEOF(.divmmc04d7) == 3,
       "DivMMC 0x04D7 guard has the wrong size")
ASSERT(ADDR(.ldbytes055c) == 0x055C,
       "DivMMC-safe LD-BYTES hook moved")
ASSERT(SIZEOF(.ldbytes055c) == 3,
       "DivMMC-safe LD-BYTES hook must be one JP")
ASSERT(ADDR(.divmmctape) == 0x055F,
       "DivMMC tape-trigger guard moved")
ASSERT(SIZEOF(.divmmctape) == 0x0C,
       "DivMMC tape-trigger guard has the wrong size")
ASSERT(__Hbss <= 0x1000,
       "Page-zero ROM exceeds 4 KiB")
}
