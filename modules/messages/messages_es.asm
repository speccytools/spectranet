.data 
.globl STRING_TABLE
STRING_TABLE:
STR_SUCCESS:    defb    "Exito",0
STR_EPERM:      defb    "Operacion no permitida",0
STR_ENOENT:     defb    "No existe archivo o directorio",0
STR_EIO:        defb    "Error E/S",0
STR_ENXIO:      defb    "Sin dispositivo o direccion",0
STR_E2BIG:      defb    "Demasiados argumentos",0
STR_EBADF:      defb    "Descriptor incorrecto",0
STR_EAGAIN:     defb    "Operacion bloquearia",0
STR_ENOMEM:     defb    "Sin memoria",0
STR_EACCES:     defb    "Permiso denegado",0
STR_EBUSY:      defb    "Dispositivo ocupado",0
STR_EEXIST:     defb    "Archivo existe",0
STR_ENOTDIR:    defb    "No es directorio",0
STR_EISDIR:     defb    "Es directorio",0
STR_EINVAL:     defb    "Argumento no valido",0
STR_ENFILE:     defb    "Tabla de archivos llena",0
STR_EMFILE:     defb    "Demasiados archivos abiertos",0
STR_EFBIG:      defb    "Archivo demasiado grande",0
STR_ENOSPC:     defb    "Sistema lleno",0
STR_ESPIPE:     defb    "Seek en pipe",0
STR_EROFS:      defb    "Sistema solo lectura",0
STR_ENAMETOOLONG: defb   "Nombre demasiado largo",0
STR_ENOSYS:     defb    "No implementado",0
STR_ENOTEMPTY:  defb    "Directorio no vacio",0
STR_ELOOP:      defb    "Demasiados enlaces",0
STR_ENODATA:    defb    "Sin datos disponibles",0
STR_ENOSTR:     defb    "Sin streams",0
STR_EPROTO:     defb    "Error de protocolo",0
STR_EBADFD:     defb    "Estado fd incorrecto",0
STR_EUSERS:     defb    "Demasiados usuarios",0
STR_ENOBUFS:    defb    "Sin buffers",0
STR_EALREADY:   defb    "Operacion en curso",0
STR_ESTALE:     defb    "Handle TNFS obsoleto",0
STR_EOF:        defb    "Fin de archivo",0

STR_TIMEOUT:    defb    "Tiempo agotado",0
STR_NOTMOUNTED: defb    "Sistema no montado",0
STR_BADLENGTH:  defb    "Longitud de cabecera mala",0
STR_BADTYPE:    defb    "Tipo de bloque malo",0
STR_UNKTYPE:    defb    "Tipo de archivo desconocido",0
STR_MISMCHLEN:  defb    "Longitud de bloque distinta",0
STR_EBADURL:    defb    "URL incorrecta",0
STR_EBADFS:     defb    "Numero de sistema malo",0
STR_EMPBUSY:    defb    "Punto de montaje usado",0
STR_EUNKPROTO:  defb    "Tipo de sistema desconocido",0

ERR_TABLE_END:
STR_UNKNOWN:    defb    "Error desconocido",0

.globl ERR_TABLE_LEN
ERR_TABLE_LEN	equ ERR_TABLE_END - STRING_TABLE

.globl STR_HITABLE
.globl HITABLE_LOWEST
STR_HITABLE:
HITABLE_LOWEST	equ 0xEC
STR_DNS_TIMEOUT:	defb	"Timeout DNS",0
STR_NO_ADDRESS:	defb	"Sin direccion",0
STR_NO_RECOVERY:	defb	"Sin recuperacion",0
STR_HOST_NOT_FOUND: defb	"Host no encontrado",0
		defb 0,0,0,0,0,0,0,0,0,0
STR_ECONNREFUSED: defb	"Conexion rechazada",0
STR_ETIMEDOUT:	defb	"Timeout socket",0
STR_ECONNRESET:	defb	"Conexion reiniciada",0
STR_ESBADF:	defb	"Descriptor socket malo",0
STR_ESNFILE:	defb	"Descriptor socket invalido",0
STR_EUNK:	defb	"Error general de socket",0
HITABLE_END:

.globl HITABLE_LEN
HITABLE_LEN	equ HITABLE_END - STR_HITABLE
