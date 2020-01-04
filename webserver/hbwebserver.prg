/** hbwebserver  Servidor Web sencillo en harbour. 
 *               Este servidor corre como un hilo en el proyecto tpuy-server.
 */


/*

* Para ejecutar la primera vez, es necesario crear los certificados.
* To run the first time, it is necessary to create the certificates.

openssl genrsa -out privatekey.pem 2048
openssl req -new -subj "/C=LT/CN=mycompany.org/O=My Company" -key privatekey.pem -out certrequest.csr
openssl x509 -req -days 730 -in certrequest.csr -signkey privatekey.pem -out certificate.pem
openssl x509 -in certificate.pem -text -noout
*/


REQUEST __HBEXTERN__HBSSL__

REQUEST DBFCDX

MEMVAR server, get, post, cookie, session

STATIC oServer, oApp, hMount


#include "include/tpy_server.ch"
#include "include/tpy_netio.ch"
#include "connect.ch"


PROCEDURE hb_webServer()

   LOCAL /*oServer,*/ lNetIO

   LOCAL oLogAccess
   LOCAL oLogError

   LOCAL nPort

   hb_cdpSelect("UTF8")

   IF hb_argCheck( "help" )
      ? "Usage: app [options]"
      ? "Options:"
      ? "  //help               Print help"
      ? "  //stop               Stop running server"
      RETURN
   ENDIF

   IF hb_argCheck( "stop" )
      hb_MemoWrit( ".uhttpd.stop", "" )
      RETURN
   ELSE
      FErase( ".uhttpd.stop" )
   ENDIF

   Set( _SET_DATEFORMAT, "yyyy-mm-dd" )

   oLogAccess := UHttpdLog():New( "hbws_access.log" )

   IF ! oLogAccess:Add( "" )
      oLogAccess:Close()
      ? "Access log file open error " + hb_ntos( FError() )
      RETURN
   ENDIF

   oLogError := UHttpdLog():New( "hbws_error.log" )

   IF ! oLogError:Add( "" )
      oLogError:Close()
      oLogAccess:Close()
      ? "Error log file open error " + hb_ntos( FError() )
      RETURN
   ENDIF

   ? "Listening on port:", nPort := 8001

   ? "CONNECTING... NetIO TPuy Server "
   lNetIO := netio_Connect( NETSERVER, NETPORT, , NETPASSWD )
   ? "netio_Connect():", lNetIO
   if !lNetIO
      tracelog "No hay conexion con el servicio NetIO de TPuy Server. "
      return
   endif
   ?
   ?

   oServer := UHttpdNew()

   oApp := TPublic():New()
//? hb_valtoexp( oApp )

   hMount := { ;
         "/tpy"                => @hbnetio() ,   ;
         "/func"               => @funcexec(),   ;
         "/hello"              => {|| UWrite( hb_StrToUTF8(~Saluda()["content"])) }, ;
         "/info"               => {|| UProcInfo() }, ;
         "/html"               => {|| URedirect( "/html/" ) }, ;
         "/html/*"             => {| x | QOut( STRTRAN(hb_DirBase(),"/bin","/html") + X ), ;
                                             UProcFiles( STRTRAN(hb_DirBase(), "/bin", "/html")  + X, .F. ) }, ;
         "/"                   => {|| URedirect( "/hello" ) } }

   IF ! oServer:Run( { ;
         "FirewallFilter"      => "", ;
         "LogAccess"           => {| m | oLogAccess:Add( m + hb_eol() ) }, ;
         "LogError"            => {| m | oLogError:Add( m + hb_eol() ) }, ;
         "Trace"               => {| ... | QOut( ... ) }, ;
         "Port"                => nPort, ;
         "Idle"                => {| o | iif( hb_FileExists( ".uhttpd.stop" ), ( FErase( ".uhttpd.stop" ), o:Stop() ), NIL ) }, ;
         "PrivateKeyFilename"  => "privatekey.pem", ;
         "CertificateFilename" => "certificate.pem", ; //"certificate.crt", ;
         "SSL"                 => .T., ;
         "Mount"               => hMount }  )

      oLogError:Close()
      oLogAccess:Close()
      ? "Server error:", oServer:cError
      ErrorLevel( 1 )
      RETURN
   ENDIF

   oLogError:Close()
   oLogAccess:Close()

   RETURN



STATIC FUNCTION funcexec()
   local oResp, aListFunc, cListFunc

   oResp := TPUBLIC():New()
//   oResp:lSensitive := .T.

   //-- primero filtrar lo solicitado a través de la lista de funciones o comandos permitidos.
   //? hb_ValToExp( get )
   cListFunc := hb_MemoRead( "LISTFUNC.txt" )
   
   aListFunc := hb_aTokens( cListFunc, hb_eol() )

   if ASCAN( aListFunc, {|a| lower(HGetKeyAt( get, 1 )) == a } ) = 0
      oResp:ok := .f.
      oResp:description := "instruction not allowed"
      oResp:result      := ""
      //UWrite( hb_StrToUTF8( hb_jsonencode(oResp:hVars) ) )
      web_message( 1, "", oResp:hVars,, .T. )
      return NIL
   endif

   oResp:ok          := .t.
   oResp:description := ""
   oResp:result      := netio_FuncExec( HGetKeyAt(get,1) )
   //UWrite( hb_jsonencode(oResp:hVars) )
   web_message( 0, "", oResp:hVars, oResp:description, .T. )

RETURN NIL



STATIC PROCEDURE tpyHeaders()
//   UAddHeader( "Content-Type", "application/json; charset=utf-8" )
   UAddHeader( "Access-Control-Allow-Origin", "*" )
   UAddHeader( "HB_API-Service-Version", "0.0.1" )
RETURN



STATIC PROCEDURE tpyCheckRequest()
   IF server[ "REQUEST_METHOD" ] == "POST" .and. !Empty( post )
      //USessionStart()
/*
//-- Dejo esto en comentario para luego ver lo de la sesion acá. RIGC(2019-08-12)
      IF ! Empty( cUser ) .AND. dbSeek( cUser, .F. ) .AND. ! Deleted() .AND. ;
            PadR( hb_HGetDef( post, "password", "" ), 16 ) == FIELD->PASSWORD
         session[ "user" ] := cUser
         URedirect( "main" )
      ELSE
         URedirect( "login?err" )
         USessionDestroy()
      ENDIF
      dbCloseArea()
*/
      get := post
   ENDIF

RETURN



/** Ejecuta un instruccion en una session dada
 */
STATIC FUNCTION tpySession( cSession )
   local uResp, nLen, uValue
   local aParams := {"__objMethod",cSession}
   local cResp := "json"
   local aResp := {"json","hb"}

   tpyHeaders()
   tpyCheckRequest()

   IF hb_HHasKey( get, "res" )
      if ASCAN( aResp, {|a| a=get["res"] } ) > 0  
         cResp := get["res"]
      endif
   ENDIF

debug hb_valtoexp( get )

//      AEVAL( hb_HKeys(get), {|o| AADD(aParams, o ) } )
   //-- Anteriormente enviabamos solo los keys del hash "get", ahora enviamos
   //   el hash completo. Asi se procesa la información mejor y como debe ser.

   nLen := LEN( get )
//tracelog "aParameters LEN", nLen
   AADD( aParams, hb_hKeyAt(get, 1) )
   //-- Si solo se recibe la instrucción y se recibe un valor, se utiliza como parametro
   if nLen=1 
      uValue := hb_hValueAt(get, 1)
      if !empty(uValue) .and. !hb_IsNIL(uValue) ; AADD( aParams, uValue ) ; endif
   //-- Si se recibe la instrucción y un solo parámetro, se extrae el valor de una vez y se envía como parámetro.
//   elseif nLen=2
//      uValue := hb_hValueAt(get, 2)
//      if !empty(uValue) .and. !hb_IsNIL(uValue) ; AADD( aParams, uValue ) ; endif
   else
      hb_hDel( get, hb_hKeyAt( get, 1) )
      AADD( aParams, get )
   endif

//debug hb_valtoexp(server)
//debug hb_valtoexp(aParams)

   uResp := hb_ExecFromArray( "FROMREMOTE", aParams )

//debug VALTYPE( uResp )

   if hb_IsHash( uResp ) .and. hb_hHasKey( uResp, "ok" )  ;
                         .and. hb_hHasKey( uResp, "type") ;
                         .and. uResp["type"]="object_id"

      oServer:SetPath( "/"+uResp["content"]["id_token"], ;
                       {|| tpySession( uResp["content"]["id_token"] ) } )
   endif
   
//      debug hb_ValToExp( uResp )
   if hb_IsHash( uResp ) 
      if hb_hHasKey( uResp, "ok" ) 
         web_message( 0, "", uResp, cResp, .T. )

         return NIL
      endif

      web_message( 0, "", uResp, cResp )

   endif
RETURN nil



STATIC FUNCTION hbnetio()
   local cCommand, uResp, oErr
   local cKey := "Sarisariñama", cPasswd
   local oResp, aListFunc, aParams := {"__objMethod"}
   local cResp := "json"
   local aResp := {"json","hb"}
   local cHome

   oResp := TPUBLIC():New( .t., .t.)

/*
   //-- primero filtrar lo solicitado a través de la lista de funciones o comandos permitidos.
   ? hb_ValToExp( get )
   aListFunc := hb_aTokens( hb_memoRead( "LISTFUNC.txt"), hb_eol() )

   if ASCAN( aListFunc, {|a| lower(HGetKeyAt( get, 1 )) == a } ) = 0
      oResp:ok := .f.
      oResp:description := "instrucción no reconocida"
      UWrite( hb_StrToUTF8( hb_jsonencode(oResp:hVars) ) )
      return ""  
   endif
*/

   tpyHeaders()
   tpyCheckRequest()

   IF hb_HHasKey( get, "res" )
      if ASCAN( aResp, {|a| a=get["res"] } ) > 0  
         cResp := get["res"]
      endif
   ENDIF

   IF hb_HHasKey( get, "login" )
      cCommand := PadR( get["login"], 1 )
      if Empty(cCommand)
         web_message( 100,"valor no reconocido",oResp:hVars, cResp )
         RETURN NIL
      endif

      if !hb_HHasKey( get, "pass" )
         web_message( 100,"desconocido",oResp:hVars, cResp )
         return .f.
      endif 

      if hb_HHasKey( get, "home")
         cHome := get["home"]
      else
         cHome := "default"
      endif
         
      cPasswd := hb_crypt( get["pass"], cKey ) 

      uResp := ~ServerLogin( get["login"], cPasswd, server[ "REMOTE_ADDR" ], cHome ) 

//tracelog "URESP", hb_valtoexp(uresp)
      
      if VALTYPE(uResp)="H"
         if !uResp["ok"] 
            //cType := VALTYPE( uResp["content"] )
            if VALTYPE( uResp["content"] )="L"
               web_message( 0, "", uResp, cResp, .T. )
            elseif uResp["content"] = "NIL"
               UAddHeader( "Content-Type", "text/html" )
               hb_IdleSleep(90)
            endif
            return NIL
         endif

         web_message( 0, "", uResp, cResp, .T. )

         oApp:Add( uResp["content"]["session_id"], "" )
         TRY
            oServer:SetPath( "/"+uResp["content"]["session_id"], ;
                             {|| tpysession( uResp["content"]["session_id"] )} )
         CATCH oErr
            ? oErr:description
         END
//? hb_valtoexp( oServer:hConfig) //["Mount"] )
//            HSet( oServer:hConfig["Mount"], uResp["content"]["session_id"], {|| URedirect( "/info" ) } )
//? hb_valToExp( oApp )

      else
TRACELOG "REVISAR!!!!!", hb_eol(), hb_valtoexp(uResp)
         UAddHeader( "Content-Type", "text/html" )
         hb_IdleSleep(90)
         return nil
      endif

   ELSE

      AEVAL( hb_HKeys(get), {|o| AADD(aParams, o ) } )
      uResp := hb_ExecFromArray( "FROMREMOTE", aParams )

      debug hb_ValToExp( uResp )

      
      if hb_IsHash( uResp ) 
         if hb_hHasKey( uResp, "ok" ) 
            web_message( 0, "", uResp, cResp, .T. )

            return NIL
         endif

         web_message( 0, "", uResp, cResp )

      endif

   ENDIF

RETURN NIL



/** Entrega el mensaje segun formato, de forma predeterminada "json"
 *
 */
STATIC FUNCTION web_message( nError, cMsg ,uContent, cType, lIgnore )
   local cResp := "", hResp

   default cType to "json" 
   default lIgnore to .F.

   if !lIgnore
      hResp := tpy_message( nError, cMsg, uContent )
   else
      hResp := uContent
   endif

   tpyHeaders()
   Do Case
   Case cType="hb"
      UAddHeader( "Content-Type", "text/html; charset=utf-8" )
      cResp := hb_valToExp( hResp )
   Other //Case cType="json"
      UAddHeader( "Content-Type", "application/json; charset=utf-8" )
      cResp := hb_jsonEncode( hResp )
   EndCase

RETURN UWrite( cResp )


//eof
