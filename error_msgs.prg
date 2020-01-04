/** error_msgs.prg  Mensajes de error del sistema.
 *  
 *  TODO: Aplicar herramientas de internacionalizacion.
 *  Esto es un intento por gestionar mensajes, hay que hacerlo como debe ser usando 
 *  los procedimientos ya implementados en harbour.  
 *  Esperemos en un plazo corto estar haciendo algo al respecto.
 */

#include "tpy_server.ch"

function err_msg( nError, cLang )
   local cMsg := "", hMsg, cErrNo

   default cLang to "es"

   if empty( nError )
      return cMsg
   endif

   cErrNo := ALLTRIM(CStr(nError))

   hMsg := {;
           "001" => "problema al intentar generar una consulta.",;
           "050" => "no se reconoce el objeto.",;
           "060" => "No se pudo crear la sesion.",;
           "099" => "MENSAJE PERSONALIZADO",;
           "100" => "mensaje no reconocido",;
           "101" => "el valor de nombre o contraseña es incorrecto.",;
           "102" => "acceso bloqueado.",;
           "103" => "Instrucción no permitida.",;
           "500" => "problema desconocido";
           }

   if hb_hHasKey( hMsg, cErrNo )
      cMsg := hb_hGet( hMsg, cErrNo )
   endif

return cMsg

//eof
