.include	"ctrlchars.inc"

; ROM configuration utility - Spanish strings
.data
.globl STR_installed
.globl STR_datarom
STR_installed:	defb "Configuracion actual",NEWLINE,"====================",NEWLINE,NEWLINE,0
STR_datarom:	defb "-- datos --",NEWLINE,0

.globl STR_menutitle
.globl STR_addmodule
.globl STR_remmodule
.globl STR_repmodule
.globl STR_exit
STR_menutitle:	defb NEWLINE,NEWLINE,"Menu configuracion ROM",NEWLINE,"======================",NEWLINE,NEWLINE,0
STR_addmodule:	defb "Anadir modulo ROM",0
STR_repmodule:	defb "Reemplazar modulo",0
STR_remmodule:	defb "Borrar modulo",0
STR_exit:	defb "Salir",0

.globl STR_send
.globl STR_port
.globl STR_xtoexit
.globl STR_borked
.globl STR_est
.globl STR_len
.globl STR_noroom
.globl STR_writingmod
STR_send:	defb "Escuchando en ",0
STR_port:	defb " puerto 2000",NEWLINE,0
STR_xtoexit:	defb NEWLINE,"Pulse 'x' para salir.",NEWLINE,0
STR_borked:	defb NEWLINE,"Operacion fallo rc=",0
STR_est:	defb "Conexion establecida",NEWLINE,0
STR_len:	defb "Tamano: ",0
STR_noroom:	defb "Sin espacio en flash.",NEWLINE,0
STR_writingmod:	defb NEWLINE,"Escribiendo modulo en pagina ",0

.globl STR_entermod
.globl STR_delrom
.globl STR_notvalid
.globl STR_erasebork
.globl STR_writebork
.globl STR_defragment
.globl STR_erasing
.globl STR_eraseok
STR_entermod:	defb "ROM hex a reemplazar: ",0
STR_delrom:	defb "ROM hex a borrar: ",0
STR_notvalid:	defb NEWLINE,"ROM no valido.",NEWLINE,"Reintente: ",0
STR_erasebork:	defb "Fallo al borrar",NEWLINE,0
STR_writebork:	defb "Fallo al escribir",NEWLINE,0
STR_defragment:	defb "Desfragmentando...",NEWLINE,0
STR_erasing:	defb NEWLINE,"Borrando...",NEWLINE,0
STR_eraseok:	defb "Borrado completo",NEWLINE,0
