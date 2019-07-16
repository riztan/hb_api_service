/** hbwebserver  Servidor Web sencillo en harbour. 
 *               Este servidor corre como un hilo en el proyecto tpuy-server.
 */


/*

* Para ejecutar la primera vez, es necesario crear los certificados.

openssl genrsa -out privatekey.pem 2048
openssl req -new -subj "/C=LT/CN=mycompany.org/O=My Company" -key privatekey.pem -out certrequest.csr
openssl x509 -req -days 730 -in certrequest.csr -signkey privatekey.pem -out certificate.pem
openssl x509 -in certificate.pem -text -noout
*/


REQUEST __HBEXTERN__HBSSL__

REQUEST DBFCDX

MEMVAR server, get, post, cookie, session, hData


#include "include/tpy_server.ch"
#include "include/tpy_netio.ch"
#include "connect.ch"


PROCEDURE hb_webServer()

   LOCAL oServer, lNetIO

   LOCAL oLogAccess
   LOCAL oLogError

   LOCAL nPort

   hData := { "data" => {1,1,1,1,1} }

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
         "Mount"               => { ;
         "/tpy"                => @hbnetio() ,   ;
         "/func"               => @funcexec(),   ;
         "/uctoutf8"           => @proc_uctoutf8(), ;
         "/hello"              => {|| UWrite( ~Saluda() ) }, ;
         "/info"               => {|| UProcInfo() }, ;
         "/"                   => {|| URedirect( "/hello" ) } } } )
      oLogError:Close()
      oLogAccess:Close()
      ? "Server error:", oServer:cError
      ErrorLevel( 1 )
      RETURN
   ENDIF

   oLogError:Close()
   oLogAccess:Close()

   RETURN




STATIC FUNCTION proc_uctoutf8()
   local cCode, hResult, cResult
   local cResp := "json"
   local aResp := {"json","hb"}

   IF hb_HHasKey( get, "code" )
      cCode := PadR( get["code"], 5 )
      if Empty(cCode) ; RETURN NIL ; endif
   ENDIF

   IF hb_HHasKey( get, "res" )
      if ASCAN( aResp, {|a| a=get["res"] } ) > 0  
         cResp := get["res"]
      endif
   ENDIF

   cResult := net:uctoutf8( cCode )
   if Empty( cResult )
      RETURN NIL
   endif

   hResult := { "utf8"=>cResult, "string" => hb_hextostr(cResult) }

   Do Case 
      Case cResp = "json"
         UWrite( hb_jsonEncode( hResult ) ) 
      Case cResp = "hb"
         UWrite( hb_ValToExp( cResult ) )
   EndCase

   RETURN NIL



STATIC FUNCTION funcexec()
   local cCommand, uResp
   local cClave := "Sarisariñama", cPasswd
   local oResp, aListFunc, cListFunc

   oResp := TPUBLIC():New()
//   oResp:lSensitive := .T.

   //-- primero filtrar lo solicitado a través de la lista de funciones o comandos permitidos.
   ? hb_ValToExp( get )
   cListFunc := hb_MemoRead( "LISTFUNC.txt" )
   
   aListFunc := hb_aTokens( cListFunc, hb_eol() )

   if ASCAN( aListFunc, {|a| lower(HGetKeyAt( get, 1 )) == a } ) = 0
      oResp:ok := .f.
      oResp:description := "instrucción no reconocida"
      UWrite( hb_StrToUTF8( hb_jsonencode(oResp:hVars) ) )
      return ""  
   endif

   oResp:result := netio_FuncExec( HGetKeyAt(get,1) )
   UWrite( hb_jsonencode(oResp:hVars) )

   RETURN NIL



STATIC FUNCTION hbnetio()
   local cCommand, uResp
   local cClave := "Sarisariñama", cPasswd
   local oResp, aListFunc, oSession, aParams := {"__objMethod"}
   local cResp := "json"
   local aResp := {"json","hb"}

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

   IF hb_HHasKey( get, "res" )
      if ASCAN( aResp, {|a| a=get["res"] } ) > 0  
         cResp := get["res"]
      endif
   ENDIF

//   UAddHeader( "Content-Type", "application/json; charset=utf-8" )
   UAddHeader( "Access-Control-Allow-Origin", "*" )
   UAddHeader( "TPUY_Server_Version", "0.0.1" )

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
         
      cPasswd := hb_crypt( get["pass"], cClave ) 

      uResp := ~ServerLogin( get["login"], cPasswd, server[ "REMOTE_ADDR" ] ) 

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

   Do Case
   Case cType="json"
      UAddHeader( "Content-Type", "application/json; charset=utf-8" )
      cResp := hb_jsonEncode( hResp )
   Case cType="hb"
      UAddHeader( "Content-Type", "text/html; charset=utf-8" )
      cResp := hb_valToExp( hResp )
   EndCase

RETURN UWrite( cResp )


//eof
