.include	"ctrlchars.inc"

; Spanish NMI menu strings
.data
.globl STR_wifi
STR_wifi:	defb "Modulo Wi-Fi",0
.globl STR_spectranext_settings
STR_spectranext_settings:	defb "Ajustes Spectranext",0
.globl STR_config
STR_config:	defb "Configurar red",0
.globl STR_rom
STR_rom:	defb "Gestionar modulos ROM",0
.globl STR_loader
STR_loader:	defb "Cargar datos a RAM",0
.globl STR_snapshot
STR_snapshot:	defb "Gestor de snapshots",0
.globl STR_exit
STR_exit:	defb "Salir",0
.globl STR_nmimenu
STR_nmimenu:	defb "Menu NMI de Spectranet",NEWLINE,NEWLINE,0
.globl STR_send
STR_send:	defb "Escuchando en ",0
.globl STR_port
STR_port:	defb " puerto 2000",NEWLINE,0
.globl STR_start
STR_start:	defb " Inicio: ",0
.globl STR_len
STR_len:	defb "Tamano: ",0
.globl STR_xtoexit
STR_xtoexit:	defb NEWLINE,"Pulse 'x' para salir.",NEWLINE,0
.globl STR_borked
STR_borked:	defb NEWLINE,"Operacion fallo rc=",0
.globl STR_est
STR_est:	defb "Conexion establecida",NEWLINE,0
.globl STR_ident
STR_ident:	defb "ROM utilidades Spectranet",0
