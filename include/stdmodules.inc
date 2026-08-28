;The MIT License
;
;Copyright (c) 2010 Dylan Smith
;
;Permission is hereby granted, free of charge, to any person obtaining a copy
;of this software and associated documentation files (the "Software"), to deal
;in the Software without restriction, including without limitation the rights
;to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;copies of the Software, and to permit persons to whom the Software is
;furnished to do so, subject to the following conditions:
;
;The above copyright notice and this permission notice shall be included in
;all copies or substantial portions of the Software.
;
;THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
;THE SOFTWARE.

; Standard module MODCALL definitions

; TNFS module
PARSEURL	equ	0xFA00		; Parses an URL in DE, result in IX
AUTOMOUNT	equ	0xFA01		; Runs the automounter

; Configuration module
CFG_COPYCONFIG          equ 0xFE01
CFG_FINDSECTION         equ 0xFE02
CFG_GETCFSTRING         equ 0xFE03
CFG_GETCFBYTE           equ 0xFE04
CFG_GETCFWORD           equ 0xFE05
CFG_CREATESECTION       equ 0xFE06
CFG_COMMITCFG           equ 0xFE07
CFG_SETCFBYTE           equ 0xFE08
CFG_SETCFWORD           equ 0xFE09
CFG_SETCFSTRING         equ 0xFE0A
CFG_ABANDONCFG          equ 0xFE0B
CFG_RMCFGITEM		equ 0xFE0C

CFG_CREATENEWCFG        equ 0xFEFF

; esxDOS compatibility module
; The BASIC-extension module is the normal Page-B environment for a command
; returning into the Spectrum BASIC interpreter.
BAS_EXT_ROM_PAGE		equ 0x04

; esxDOS shim module ID. Keep this clear of the built-in extension modules:
; 0xFE=config, 0xFD=basext, 0xFC=messages, 0xFB=snapman, 0xFA=TNFS.
ESXDOS_ROM_ID		equ 0xF9
ESXDOS_ROM_PAGE		equ 0x05
ESXDOS_DOT_SETUP_OUTPUT equ 0x11

; esxDOS DOT ABI command-line storage. A DOT image may occupy $2000-$3DFF,
; leaving the final 512 bytes of its second page for the loader-provided line.
DOT_COMMAND_LINE		equ 0x3E00
DOT_COMMAND_LINE_PAGE_A	equ 0x1E00

ESXDOS_M_GETSETDRV	equ 0x89
ESXDOS_M_TAPEIN	    equ 0x8B
ESXDOS_F_OPEN		equ 0x9A
ESXDOS_F_CLOSE		equ 0x9B
ESXDOS_F_READ		equ 0x9D
ESXDOS_F_WRITE		equ 0x9E
ESXDOS_F_SEEK		equ 0x9F
ESXDOS_F_FSTAT		equ 0xA1
ESXDOS_F_OPENDIR	equ 0xA3
ESXDOS_F_READDIR	equ 0xA4
ESXDOS_F_TELLDIR	equ 0xA5
ESXDOS_F_SEEKDIR	equ 0xA6
ESXDOS_F_GETCWD	    equ 0xA8
ESXDOS_F_CHDIR		equ 0xA9
ESXDOS_F_MKDIR		equ 0xAA
ESXDOS_F_RMDIR		equ 0xAB
ESXDOS_F_STAT		equ 0xAC
ESXDOS_F_UNLINK		equ 0xAD
ESXDOS_F_CHMOD		equ 0xAF
ESXDOS_F_RENAME		equ 0xB0
ESXDOS_F_GETFREE	equ 0xB1
