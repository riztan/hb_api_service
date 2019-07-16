/*
 * $Id: tapp.prg 2014-01-22 17:22 riztan $
 */



//memvar oAcc, oApp

//#include "tpy_server.ch"
#include "hbclass.ch"


//-- otras clases necesarias de incluir
#include "tpuy/tsession.prg"
#include "tpuy/tcontrol.prg"


/* Definiciones de seguridad (variables) para personalizar la
   encriptación de datos

   #define TPY_PASSKEY  "cadena"
*/
#include "tpy_nofree.ch"  


/*
  Una de las principales funciones de esta clase es controlar 
  el acceso al servicio. Atender solo usuarios identificados.

  Igualmente se debe proveer un API que permita:
    - Registrar nuevos usuarios.
    - Iniciar sesion (login).
    - Obtener archivos necesarios para que una aplicacion cliente
      pueda interactuar con este servidor sin problema. 
      ( Es posible que pueda entregar código xBase, JavaScript, etc segun
        el tipo de cliente )

  Muy importante tomar en cuenta que el contenido de esta clase es
  de acceso público, por lo que solo debe incluir metodos que puedan
  ser libremente accedidos.  
  Por lo tanto, la parte administrativa de este servidor debe estar en
  otro nivel.

  SUPREMAMENTE IMPORTANTE. Pensar siempre como un atacante, pensar como 
  prevenir ataques desde un software cliente.

 */

CLASS TACC
protected:
   DATA cClassName INIT  "Clase de Acceso Publico"
   DATA hVars      INIT  hb_hash()

exported:
   METHOD New()                     INLINE Self
   //METHOD Get( cName )      INLINE  ::hVars[ cName ]
   METHOD ServerLogin(  )

   METHOD Saluda()                  INLINE "Hola. Soy un metodo en la Clase '"        +;
                                           ::ClassName+"' ("+::cClassName+")"         +;
                                           " de TPuy Server. Es un gusto saludarte, " +;
                                           "espero disfrutes la experiencia! ;) "

   METHOD ScriptList()              INLINE  GETDIR("XBS")
   METHOD ScriptGet(cScriptFile)    INLINE  FILEGET("XBS", cScriptFile)

   METHOD IncList()                 INLINE  GETDIR("INC")
   METHOD IncGet(cInclude)          INLINE  FILEGET("INC", cInclude)

   METHOD ResourceList()            INLINE  GETDIR("RES")
   METHOD ResourceGet(cResFile)     INLINE  FILEGET("RES", cResFile)

   METHOD ImageList()               INLINE  GETDIR("IMG")
   METHOD ImageGet(cImgFile)        INLINE  FILEGET("IMG", cImgFile)

   METHOD End()

   ERROR HANDLER OnError()  

ENDCLASS



METHOD OnError()  CLASS TACC
   ? MSG_LINE
   ? "***ATENCION.  CLASE TACC  ***"
   ? " Se ha solicitado ejecutar metodo o mensaje [",__GetMessage(),"] inexistente. "
   ? MSG_LINE
   return ""



/** Metodo publico para logearse en el servicio
 *
 *  ToDo: Al intentar loguearse de forma fallida, se debe incrementar la 
 *        variable que contiene el nro de intentos. Al superar N veces, debe
 *        comenzar a ignorar ese usuario. (deberíamos detectar la IP)
 *
 */
METHOD ServerLogin( cUser, cPasswd, cIp ) CLASS TACC
   local cQry, oQry, oConn, oSession, cSessionId, cMD5Pass:=''
   local hAttemp, ntDiff
   local nMinBlock := 10  // Minutos de Bloqueo del cliente
   local nAttBlock := 5   // Maximo de Intentos fallidos permitidos.
   local lResp    := .f.
   local lIsUser  := .f.
   local nAttemps := 1
   local hResp

   //debug cUser, " - ", cPasswd

   default cIp to ""

   nAttemps := 0

//debug cIp, cUser, cPasswd

   IF hb_IsNil( cUser ) .or. hb_IsNil( cPasswd ) .or. Empty( cIp )
      debug "Retornamos NULO, no se cumplen las condiciones."
      Return NIL
   ENDIF

   If !Empty( cPasswd ) 
      cPasswd  := "tpy"+hb_Decrypt( cPasswd, TPY_PASSKEY )+"123"
      cMD5Pass := hb_MD5( cPasswd )
   endif


   // En este punto, se verifica si realmente es un usuario valido.
   lIsUser := oApp:CheckUser( cUser, cPasswd ) //cMD5Pass )

/*
   If ::IsDef(cUser) .AND. hb_IsObject( ::Get(cUser) )
      Return NIL //::Get(cUser)
   EndIf
*/   

   if !lIsUser
      // -- Contabilizar el intento fallido. 
      // -- Intentar generar registro que pueda ser procesado por DenyHost o similar.

#ifdef __HELP__
      tracelog MSG_LINE
      tracelog "Intento Fallido: IP [", cIp, "]  usuario: [", cUser, "]"
      tracelog "Se procede a registrar los datos del usuario y dirección ip en el objeto ",hb_eol(),;
               "de control de intentos fallidos.  Si se contabiliza 10 intentos, se bloquea ",hb_eol(),;
               "el usuario. "
      ?
#endif
debug "Encontrado usuario: ", oApp:oFAttemps:IsDef( cIp )
//debug "Contenido de oFAttemps:", hb_valToExp(oApp:oFAttemps)

      if oApp:oFAttemps:IsDef( cIp )
         hAttemp := oApp:oFAttemps:Get( cIp )
         ntDiff   := hb_NToMin( hb_DateTime() - hAttemp["last_time"] )
         nAttemps := iif( ntDiff > nMinBlock, 0, hAttemp["attemps"]++ )

         if nAttemps >= nAttBlock 
            tracelog "Tiempo transcurrido. ", ntDiff
            if hb_NToMin( hb_DateTime() - hAttemp["last_time"] ) < 1
               // -- bloquear acceso desde esa IP. #TODO #RIGC
               tracelog "PROCESO DE BLOQUEO DE USUARIO." 
               hAttemp["last_time"] := hb_DateTime()
               RETURN tpy_message(102, "", NIL )
            else
               hAttemp["attemps"] := 0
               nAttemps := 0
            endif
         endif
         hAttemp["last_time"] := hb_DateTime()
      else
         hAttemp := { "ip"        => cIp,            ;
                      "attemps"   => nAttemps,       ;
                      "last_time" => hb_DateTime() } 
         oApp:oFAttemps:Add( cIp, hAttemp )
      endif
      
#ifdef __HELP__
      tracelog MSG_LINE
      tracelog "Nro de intentos fallidos:", nAttemps
      tracelog MSG_LINE
#endif
//      oApp:oFAttemps:Get( cIp )[ "LastTime" ] := hb_DateTime()
//      hb_hSet( ::hVars, "lasttime", hb_DateTime() )
      RETURN tpy_message( 101, "valor de nombre o contraseña es incorrecto", .F. )

   endif


   /* Valor que identifica la sesion que se va a crear */
   cSessionId := hb_MD5( "tpy"+cUser+DTOC(Date()) ) //cUser+"|"+LEFT(hb_MD5("tpy"+cUser),4)
debug "identificador de la sesion del usuario",cSessionId
   
   if oApp:oSession:IsDef( cSessionId )

//   En este segmento intentamos verificar si el usuario ya tiene una sesion abierta, 
//   y en ese caso, lo recomendable es entregarle esa sesion abierta.     

tracelog MSG_LINE
tracelog " USUARIO "+cUser+" REGISTRADO "
tracelog MSG_LINE

      oSession := oApp:oSession:Get( cSessionId ) // Ya el usuario debe ser un objeto de la clase "CONTROL"
//      oSession:cMsg := "Usuario Ya Registrado."

//tracelog " ::oLServer:GetConn( ",::oLServer:cConnDefault," ) => ",::oLServer:GetConn(::oLServer:cConnDefault):ClassName()

      hResp := tpy_message( 0,"", { "session_id" => oSession:cId,;
                                    "user_data"  => oSession:UserData() } )

      return hResp //oSession 
   else

tracelog "La sesion del usuario ",cUser,"NO esta definida! Por lo tanto se procede a registrarla... "

      oSession := TSession():New( cSessionId, cUser, cIp  )
      oApp:oSession:Add( cSessionId, oSession )

   endif

/*
   if !::IsDef( "oServer" )
      ::Add("oServer", DbServer():New("pg", "pg_tpy") )
      if !Check_Connection( ::oServer )
         return nil
      endif
   endif
*/
   if !hb_IsObject( oSession )
      debug "El objeto del usuario no se ha podido crear, se retorna .F. "
      return .f.
   endif
      
   oSession:tLastActivity  := hb_DateTime()

//debug "Session ",hb_eol(), hb_valtoexp( oSession )

   hResp := tpy_message( 0,"", { "session_id" => oSession:cId,;
                                 "user_data"  => oSession:UserData() } )

   /* ConexiÃ³n para el usuario.. debo crear conexiÃ³n a partir de los datos del usuario. */
   //::Add(cUser,oUser)
   
RETURN hResp //oSession




/** Finaliza el objeto.
 *
 */
METHOD END()  CLASS TACC

   ::hVars := NIL

RETURN Self



STATIC FUNCTION FILEGET( cType, cFile )
   local cTpyDir := "tpy_apps/tpy_base/"  //"/opt/tpy-apps/tpy_base/"
   local cDirName, cBody

   default cType to ""
   default cFile to ""

   if empty( cFile ) ; return nil ; endif

   if cType = "INC"
      cDirName := cTpyDir+"include"
   elseif cType = "RES"
      cDirName := cTpyDir+"resources"
   elseif cType = "IMG"
      cDirName := cTpyDir+"images"
   elseif cType = "XBS"
      cDirName := cTpyDir+"xbscripts"
   else
      return nil
   endif

debug cDirName+"/"+cFile
   cBody := MemoRead( cDirName + "/" + cFile )

RETURN cBody



STATIC FUNCTION GetDir( cType ) 
   local aAux, aResult := {}
   local cTpyDir := "tpy_apps/tpy_base/" 
   local nFiles, cFileName
   local cDirName

   default cType to ""

   if Empty( cType ) ; return nil ; endif

   if cType = "INC"
      cDirName := cTpyDir+"include"
   elseif cType = "RES"
      cDirName := cTpyDir+"resources"
   elseif cType = "IMG"
      cDirName := cTpyDir+"images"
   elseif cType = "XBS"
      cDirName := cTpyDir+"xbscripts"
   else
      return nil
   endif

   nFiles := ADir( cDirName+"/*" )
   aAux := ARRAY(nFiles)
   ADIR( cDirName+"/*", aAux )

   FOR EACH cFileName IN aAux
      if cFileName != "connect.ch"
         AADD( aResult, { cFileName, hb_MD5( MemoRead(cDirName+"/"+cFileName) ) } )
      endif
   NEXT

RETURN aResult




//EOF
