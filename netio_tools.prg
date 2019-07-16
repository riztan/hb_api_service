/*
 * $Id: client.prg 2011-12-28 17:26 riztan $
 */

/*
 *
 * Copyright 2011 Riztan Gutierrez <riztan / at / gmail.com>
 *
 */

/*
 * Convierte un Valor en Cadena de Texto que puede ser 
 * reconvertido mediante hb_Deserialize()
 */

#include "tpy_server.ch"

 
function Value2Remote(uData)

   local cText:="", cType
      
   cType := ValType( uData )
      
      switch cType 
      case "O"
           cText = hb_Serialize('"obj_'+uData:ClassName()+'"')
           exit      
      case "B"
           cText = hb_Serialize("_codeblock_")
           exit
      case "P"
           cText = hb_Serialize("_pointer_")
           exit
      otherwise
           cText = hb_Serialize( udata )
           exit
      endswitch
      
return cText



/*
 * Convierte un Array en Cadena de Texto que puede ser 
 * reconvertida mediante macrosustitucion &
 */
function Array2CSV(aData)

   local cText
   local uItem
   
   if !hb_IsArray(aData) ; return uValToChar( aData ) ; endif
   
   cText :="{"
   
   for each uItem in aData

      cText += uValToChar(uItem)
      cText += ","
   
   next
   
   cText := left(cText,LEN(cText)-1)+"}"
   
return cText


/* Convierte Un Valor a Cadena */
/* Source from hbsocket of Daniel Garcia-Gil. */
static function uValToChar( uVal )

   local cType := ValType( uVal )

   do case
      case cType == "C" .or. cType == "M" .or. cType == "D"
           return ValToPrg(uVal)

      case cType == "T"
           return If( Year( uVal ) == 0, HB_TToC( uVal, '', Set( _SET_TIMEFORMAT ) ), HB_TToC( uVal ) )

      case cType == "L"
           return If( uVal, ".T.", ".F." )

      case cType == "N"
           return AllTrim( Str( uVal ) )

      case cType == "B"
           return "{|| ... }"

      case cType == "A"
           return Array2CSV( uVal )   //"{...}"

      case cType == "O"
           return If( __ObjHasData( uVal, "cClassName" ), uVal:cClassName, uVal:ClassName() )

      case cType == "H"
           return ValToPrg( uVal )    //"{=>}"

      case cType == "P"
           return "0x" + hb_NumToHex( uVal )

      otherwise

           return ""
   endcase

return nil


/** brief Retorna el contenido del archivo tpycli_version.txt
 *  debe contener el md5 del ejecutable recomendado para usar.
 */
function tpycli_version( cOS, cAction )
   local cFileName := ""
   local cPath     := ""
   local cMD5File  := ""
   local cLine, aLine, cFileCnf

//   default cOS to "windows"
   default cAction to ""

   if hb_IsNIL( cOS )
      cOS := IIF( "WINDOWS" $ OS(), "windows", "linux" )
   else
      cOS := lower( cOS )
      if ( cOS $ "ubuntu,debian" ) ; cOS := "linux" ; endif
   endif

   if ( "linux" $ cOS )
      cFileCnf := "tpy_server_gnu.cnf"
   elseif ( "win" $ cOS )
      cFileCnf := "tpy_server_win.cnf"
   endif

   FOR EACH cLine IN hb_aTokens( MemoRead( cFileCnf ), CHR(10) )
      if LEN(cLine)>2
         cLine := ALLTRIM(cLine)
         if !Empty(ALLTRIM(cLine)) .and. !( LEFT( cLine, 1 ) $ "#,*" )
            aLine := hb_aTokens( cLine, "=" )
            if LEN(aLine)=2
               
               Do Case
               Case ALLTRIM( UPPER(aLine[1]) ) = "CFILENAME"
//debug "Encontrado ",cLine
                  cFileName := STRTRAN( ALLTRIM(aLine[2]), '"', '' )
               Case ALLTRIM( UPPER(aLine[1]) ) = "CPATH"
//debug "Encontrado ",cLine
                  cPath := STRTRAN( ALLTRIM(aLine[2]), '"', '' )
               EndCase

            endif
         endif
      endif
   NEXT

   if cOS = "windows"
      cMD5File := STRTRAN( cFileName, ".exe", ".md5" )
   else
      cMD5File := cFileName+".md5"
   endif

   if Empty(cAction)

      if FILE( cMD5File )
         return MemoRead( cMD5File )
      else
         if FILE( cPath + cFileName )
            if hb_MemoWrit( cPath + cMD5File, hb_MD5File( cPath + cFileName ) )
               return MemoRead( cPath + cMD5File )
            endif
         endif
      endif

   elseif cAction = "get"
debug "verificando  " + cPath + cFileName
      if FILE( cPath + cFileName )

debug "regresando el contenido..."
         return MemoRead( cPath + cFileName )

      endif

   endif
      
return nil


function tpycli_get_version( cOS )
return  tpycli_version( cOs, "get" )

//eof

