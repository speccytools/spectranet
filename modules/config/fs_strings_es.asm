.include	"ctrlchars.inc"
.data
.globl STR_fsnum
STR_fsnum:	defb	"Sistema: ",0
.globl STR_unset
STR_unset:	defb	"<sin definir>",NEWLINE,0
.globl STR_geturl
STR_geturl:	defb	NEWLINE,"URL del sistema:",NEWLINE,"> ",0
.globl STR_invalidurl
STR_invalidurl:	defb	"URL no valida",NEWLINE,0
.globl STR_committed
STR_committed:	defb	"Guardado OK.",NEWLINE,0
.globl STR_committing
STR_committing:	defb	"Escribiendo...",NEWLINE,0
.globl STR_commitfail
STR_commitfail:	defb	"Fallo al guardar.",NEWLINE,0
.globl STR_abandoned
STR_abandoned:	defb	"Cambios descartados.",NEWLINE,0
.globl STR_invalidfs
STR_invalidfs:	defb	"URL no valida",NEWLINE,0
.globl STR_unable
STR_unable:	defb	"No se pudo ajustar item",NEWLINE,0
.globl STR_createfail
STR_createfail:	defb	"No se pudo crear seccion",NEWLINE,0
.globl STR_bootflag
STR_bootflag:	defb	NEWLINE,"Autoarranque: ",0

.globl STR_seturl
STR_seturl:	defb	"Asignar sistema",0
.globl STR_unseturl
STR_unseturl:	defb	"Quitar sistema",0
.globl STR_setboot
STR_setboot:	defb	"Activar autoarranque",0
.globl STR_saveexit
STR_saveexit:	defb	"Guardar y salir",0
.globl STR_abandon
STR_abandon:	defb	"Descartar y salir",0
.globl STR_separator
STR_separator:	defb	NEWLINE,"========================================",NEWLINE,NEWLINE,0

.globl STR_basicinit
STR_basicinit:	defb	"Extensiones config OK",NEWLINE,0
.globl STR_basinsterr
STR_basinsterr:	defb	"No se pudo iniciar config",NEWLINE,0
.globl STR_ident
STR_ident:	defb	"Configuracion 1.0",0
