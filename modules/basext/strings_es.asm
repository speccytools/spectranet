.data
.globl STR_filetype
.globl STR_tap
.globl STR_data
.globl STR_basic
.globl STR_numarray
.globl STR_strarray
.globl STR_code
.globl STR_unknown
.globl STR_size
.globl STR_blksize
.globl STR_param1
.globl STR_param2
.globl STR_directory
.globl STR_bytes
.globl STR_headerless
STR_filetype:	defb	"Tipo: ",0
STR_tap:	defb	"Archivo TAP",0
STR_data:	defb	"Datos",0
STR_basic:	defb	"Programa: ",0
STR_numarray:	defb	"Array num: ",0
STR_strarray:	defb	"Array str: ",0
STR_code:	defb	"Bytes: ",0
STR_unknown:	defb	"Desconocido: ",0
STR_size:	defb	"Tamano: ",0
STR_blksize:	defb	"Bloque: ",0
STR_param1:	defb	"Parametro 1: ",0
STR_param2:	defb	"Parametro 2: ",0
STR_directory:	defb	"Directorio: tamano ",0
STR_bytes:	defb	" bytes",0
STR_headerless:	defb	"Bloque sin cabecera: ",0
