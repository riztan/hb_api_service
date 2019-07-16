/*
 * $Id: tpy_serv.prg 2014-01-10 18:08 riztan $
 */

/*
 * Funciones para uso en Servidor NetIO de Tpuy.
 *
 * Copyright 2011 Riztan Gutierrez <riztan / at / gmail.com>
 */

//memvar oAcc, oApp //oDbServer

//#include "tpy_server.ch"


/**  Mensaje inicial, se indica status de compilación.
 *
 */
Procedure tps_Welcome()
   local lMySQL := .f., lPgSQL := .f., lWeb := .f., lDebug := .f.

   CLEAR SCREEN

   tracelog MSG_LINE
   tracelog "Iniciando Servidor TPuy."
   tracelog MSG_LINE
#ifdef __DEBUG__
  #ifdef __MYSQL__
   lMySQL := .t.
  #endif
  #ifdef __POSTGRESQL__
   lPgSQL := .t.
  #endif
  #ifdef __WEBSERVICE__
   lWeb := .t.
  #endif
   tracelog "    Soporte a MySQL:        "+IIF(lMySql,"SI","NO")
   tracelog "    Soporte a PostgreSQL:   "+IIF(lPgSql,"SI","NO")
   tracelog "    Servidor Web Incluido:  "+IIF(lWeb  ,"SI","NO")
  #ifdef __DEBUG__
   lDebug := .t.
   tracelog "  ** MODO DEBUG ACTIVADO. ** "
  #endif
#endif
RETURN



/** Finalización de la ejecución.
 *     Se cierras los objetos abiertos.
 *
 */
procedure tps_End()
   //debug "Cerrando oDbServer"
   //oDbServer:End()
   debug "Cerrando objeto de acceso publico oAcc"
   oAcc:End()
return



/** Gestión de mensajes en la terminal.
 */
procedure tps_Log( nType, procname, procline, ... )
   if nType = 0
      QOUT( procname+" ("+ALLTRIM(STRZERO(procline,6))+"): ", ... )
   endif
#ifdef __DEBUG__
   if nType = 1
      QOUT( "<DEBUG> ", procname+" ("+ALLTRIM(STRZERO(procline,6))+"): ", ... )
   endif 
#endif   
return



/** Filtra cadena SQL a fin de evitar inyeccion.
 *
 */
function tps_SqlCheck( cString )
   if ( ";" IN cString )
      return hb_ATokens( cString, ";" )[1]
   endif
return cString


/** Procesa y ejecuta el contenido de un script
 *
 */
function tps_Analice( cFile )
   local cRes:="", aScript //,cProcesar
   local cLine, nPosI, nPosF, lIni:=.f.
   local cCode, oHrb
   local nBlock := 4096

   default cFile to "tpy_test01.xbs"

   if !File(cFile)
      tracelog "El archivo indicado no existe. "
      return ""
   endif

//? cFile
//   nHand := FOpen(cFile) //, FO_READ)

   aScript := hb_aTokens( MemoRead(cFile), hb_eol() )

   if Len(aScript)<=0
      tracelog "No hay contenido en el archivo indicado."
      Return ""
   endif


   for each cLine IN aScript

      //? cLine:__enumIndex, " ", cLine:__enumValue
      cLine := cLine:__enumValue

      nPosI := AT("<hb>",cLine)
      if nPosI > 0 .and. !lIni
         lIni := !lIni
         //cProcesar := ""

         nPosF := AT("</hb>",cLine)
         if nPosF > 0 .AND. nPosF > nPosI

            cCode := "function start() "+hb_eol()
            cCode += "return "
            cCode +=  STRTRAN(STRTRAN(SUBSTR(cLine,nPosI,nPosF),"<hb>"),"</hb>")+hb_eol()

            oHrb = HB_CompileFromBuf( cCode, "-n", "-p", "-q2", {"-I/usr/local/include/harbour"} )
            //? hb_HrbRun( oHrb )

            cLine :=  STUFF(cLine, nPosI, nPosF, hb_HrbRun( oHrb ) )

         endif
      endif

      cRes += cLine + hb_eol()
//? cRes

   next

return cRes


/**
 *
 */
function tps_Test()
/*
   LOCAL cScript

   cScript := "#include 'gclass.ch' "+CRLF
   cScript += "proce script() "+CRLF
   cScript += "  Local oWnd "+CRLF
   cScript += "  DEFINE WINDOW oWnd TITLE 'Desde el Server!!' "+CRLF
   cScript += "  ACTIVATE WINDOW oWnd "+CRLF
   cScript += "return "+CRLF

//? cScript
*/
//return memoread('main.xbs')
return tps_Analice()


/** Ejecuta el script indicado. 
 *
 */
function tps_Script( cFile )
   local cNombre

   if UPPER(RIGHT(ALLTRIM(cFile),4))=".XBS"
      Return tps_Analice(cFile)
   endif

return tps_Analice(cFile+".xbs")


/** Genera un codigo para hacer validaciones de usuarios a registrar
 *
 */
function tps_GenCode( cLogin, lForce )
   Local cValue := "00000"
   Local cFile 

   default lForce to .f.

   if hb_IsNil(cLogin) ; return cValue ; endif

   cFile := ".tmp/tpy_" + AllTrim(cLogin) + ".usr"
   if File( cFile ) .and. !lForce
      Return hb_MemoRead( cFile )
   endif

   cValue := RIGHT(AllTrim( STR( Second()*10 ) ), 5 )
   hb_MemoWrit( cFile, cValue)

return cValue


/** Verifica un codigo dado contra el generado internamente.
 *
 */
function tps_IsCode( cCode, cLogin )
   Local lResp := .f.
   Local cFile, cTxt

   if Empty(cLogin) .or. Valtype(cLogin)!="C"
      return .f.
   endif

   cFile := ".tmp/tpy_"+Alltrim(cLogin)+".usr"

   if File( cFile )
      cTxt := MemoRead(cFile)

      if MemoRead( cFile ) == cCode
         lResp := .t.
      endif
   endif
return lResp




//eof
