.include	"ctrlchars.inc"

.data
.globl UI_STRINGS
.globl INPUTTABLE
.globl INPUTADDRS
.globl STR_filename
.globl STR_cfoverwrite
.globl STR_loading
.globl STR_saving
.globl STR_cwd
.globl STR_ident
.globl STR_initialized
.globl STR_failed
.globl STR_nomempage
.globl STR_curfile
.globl STR_nofile
.globl STR_newname
.globl STR_cferase
.globl STR_selectfs_title
.globl STR_selectfs_prompt
.globl STR_selectfs_exit
.globl STR_fs1
.globl STR_fs2
.globl STR_fs3
.globl STR_fs4
.globl STR_mounted
.globl STR_unmounted
.globl STR_unknown
.globl STR_currentmount
.globl STR_newline
.globl CHAR_YES
UI_STRINGS:     defb    0,5,"- GESTOR SNAPSHOT SPECTRANET -",0
                defb    1,0,"Cursores mueven, Enter selecciona",0
                defb    3,28,"[D] Directorio/",0
                defb    4,32,"archivo",0
                defb    6,28,"[C] Guardar como...",0
                defb    8,28,"[S] Guardar",0
                defb    10,28,"[R] Renombrar",0
                defb    12,28,"[E] Borrar",0
                defb    18,28,"[Q] Salir",0
                defb    20,0,"Dir: ",0
                defb    0xFF,0xFF
INPUTTABLE:     defb    "qd",0x0d,"csre",0
INPUTADDRS:     defw    F_exit
                defw    F_switchdirview
                defw    F_enterpressed
                defw    F_saveas
                defw    F_save
		defw	F_rename
		defw	F_erase

CHAR_YES:       equ     's'
STR_filename:   defb    "Archivo: ",0
STR_cfoverwrite: defb    "Sobrescribir archivo? (s/n): ",0
STR_loading:	defb	"Cargando...",0
STR_saving:	defb	"Guardando...",0
STR_cwd:	defb	".",0
STR_ident:	defb	"Gestor snapshots 1.0",0
STR_initialized: defb	"Gestor snapshots iniciado",NEWLINE,0
STR_failed:	defb	"Sin memoria para snapmgr",NEWLINE,0
STR_nomempage:	defb	"No se asigno pagina",NEWLINE,0
STR_curfile:	defb	"Actual: ",0
STR_nofile:	defb	"(ninguno)",0
STR_newname:	defb	"Nuevo nombre> ",0
STR_cferase:	defb	"Borrar archivo? (s/n): ",0
STR_selectfs_title: defb "ELEGIR SISTEMA SNAPSHOT", NEWLINE, NEWLINE, 0
STR_selectfs_prompt: defb "Elija slot para cargar o", NEWLINE, "guardar snapshots:", NEWLINE, NEWLINE, 0
STR_selectfs_exit: defb "Pulse 9 para salir.", NEWLINE, 0
STR_fs1:	defb	NEWLINE, "1 (slot 0): ",NEWLINE,0
STR_fs2:	defb	NEWLINE, "2 (slot 1): ",NEWLINE,0
STR_fs3:	defb	NEWLINE, "3 (slot 2): ",NEWLINE,0
STR_fs4:	defb	NEWLINE, "4 (slot 3): ",NEWLINE,0
STR_mounted:	defb	"MONTADO",0
STR_unmounted:	defb	"SIN MONTAR",0
STR_unknown:	defb	"DESCONOCIDO",0
STR_currentmount: defb NEWLINE, "  * ACTUAL",0
STR_newline:	defb	NEWLINE,0
