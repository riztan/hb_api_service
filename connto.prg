/** \brief Crea el objeto de conexion con el servidor indicado.
    \return Devuelve el objeto si realizó la conexión. Caso contrario 
     devuelve nulo.
 */

#ifdef __MYSQL__
#include "tdolphin.ch"
#include "hbcompat.ch"

FUNCTION ConnectTo( cServer )
   LOCAL c 
   LOCAL hIni      
   LOCAL oServer:=NIL
   LOCAL cDbType,cHost, cUser, cPassword, nPort, cDBName,nFlags,cSchema    
   LOCAL oErr

   c = "tpy"
   
   if cServer != NIL 
      c = cServer 
   endif
   
   hIni      := HB_ReadIni( "connect.ini" )
   oServer   := NIL
   cDBType   := hIni[ cServer ]["srv"]
   cHost     := hIni[ cServer ]["host"]
   cUser     := hIni[ cServer ]["user"]
   cPassword := hIni[ cServer ]["psw"]
   nPort     := val(hIni[ cServer ]["port"])
   cDBName   := hIni[ cServer ]["dbname"]
//   nFlags    := val(hIni[ cServer ]["flags"])

      
   TRY
      if cDBType == "mysql"
         CONNECT oServer HOST cHost ;
                         USER cUser ;
                         PASSWORD cPassword ;
                         PORT nPort ;
                         FLAGS val(hIni[ cServer ]["flags"]) ;
                         DATABASE cDBName

      elseif cDBType == "pgsql"
         oServer := TPQServer():New( cHost,     ;
                                     cDBName,   ; 
                                     cUser,     ;
                                     cPassword, ;
                                     nPort,     ;
                                     hIni[cServer]["schema"] )
//      else
//         MsgLog("Tipo de Base de datos desconocido.")
      endif
                                
   CATCH oErr 
     RETURN NIL
   END
   
RETURN oServer

#endif
//EOF
