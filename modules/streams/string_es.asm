.include	"ctrlchars.inc"

; Spanish strings
.data
.globl STR_basicinit
.globl STR_basinsterr
.globl STR_nomem
.globl STR_sockerr
.globl STR_closeerr
.globl STR_nobuferr
.globl STR_fileerr
.globl STR_direrr
STR_basicinit:	defb	"Soporte BASIC streams iniciado",NEWLINE,0
STR_basinsterr:	defb	"Fallo al iniciar streams BASIC",NEWLINE,0
STR_nomem:	defb	"Sin paginas de memoria",0
STR_sockerr:	defb	"Error de socket",0
STR_closeerr:	defb	"No se pudo cerrar socket",0
STR_nobuferr:	defb	"Sin buffers",0
STR_fileerr:	defb	"Error abriendo archivo",0
STR_direrr:	defb	"Error abriendo directorio",0
