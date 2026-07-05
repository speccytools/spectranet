.include	"ctrlchars.inc"
.data
.globl STR_choose
.globl STR_dhcp
.globl STR_ipaddr
.globl STR_netmask
.globl STR_gateway
.globl STR_hostname
.globl STR_pridns
.globl STR_secdns
.globl STR_hwaddr
.globl STR_save
.globl STR_cancel
STR_choose: defb NEWLINE,NEWLINE,"Elija opcion:",NEWLINE,0
STR_dhcp: defb "Activar/desactivar DHCP",0
STR_ipaddr: defb "Cambiar direccion IP",0
STR_netmask: defb "Cambiar mascara",0
STR_gateway: defb "Cambiar gateway",0
STR_hostname: defb "Cambiar nombre host",0
STR_pridns: defb "Cambiar DNS primario",0
STR_secdns: defb "Cambiar DNS secundario",0
STR_hwaddr: defb "Cambiar direccion hardware",0
STR_save: defb "Guardar y salir",0
STR_cancel: defb "Cancelar y salir",0

.globl STR_currset
.globl STR_usedhcp
.globl STR_currip
.globl STR_currmask
.globl STR_currgw
.globl STR_currhwaddr
.globl STR_currhost
.globl STR_currpridns
.globl STR_currsecdns
.globl STR_no
.globl STR_yes
.globl STR_bydhcp
.globl STR_vunset
STR_currset: defb "Configuracion actual",NEWLINE,"====================",NEWLINE,0
STR_usedhcp: defb "Usar DHCP       : ",0
STR_currip: defb "Direccion IP    : ",0
STR_currmask: defb "Mascara         : ",0
STR_currgw: defb "Gateway         : ",0
STR_currhwaddr: defb "Direccion HW    : ",0
STR_currhost: defb "Nombre host     : ",0
STR_currpridns: defb "DNS primario    : ",0
STR_currsecdns: defb "DNS secundario  : ",0
STR_no: defb "No",NEWLINE,0
STR_yes: defb "Si",NEWLINE,0
STR_bydhcp: defb "Por DHCP",0
STR_vunset: defb "[sin definir]",0

.globl STR_abort
.globl STR_invalidip
.globl STR_dhcpquestion
.globl STR_askip
.globl STR_asknetmask
.globl STR_askgw
.globl STR_askhw
.globl STR_askhostname
.globl STR_askpridns
.globl STR_asksecdns
STR_abort: defb "Linea vacia cancela",NEWLINE,0
STR_invalidip: defb NEWLINE,"Direccion no valida.",NEWLINE,0
STR_dhcpquestion: defb NEWLINE,"Usar DHCP? (S/N): ",0
STR_askip: defb NEWLINE,"Direccion IP: ",0
STR_asknetmask: defb NEWLINE,"Mascara: ",0
STR_askgw: defb NEWLINE,"Gateway: ",0
STR_askhw: defb NEWLINE,"Direccion HW: ",0
STR_askhostname: defb NEWLINE,"Nombre host: ",0
STR_askpridns: defb NEWLINE,"DNS primario: ",0
STR_asksecdns: defb NEWLINE,"DNS secundario: ",0

.globl STR_saving
.globl STR_done
STR_saving: defb NEWLINE,"Guardando...",0
STR_done: defb "Hecho",NEWLINE,0
