/**
 *
 */


/** Envia un mensaje y sus argumentos a un objeto en el servidor.
 * De encontrar el objeto, entrega el mensaje junto con los argumentos 
 * y devuelve lo que el mismo retorna.
 * Es decir, hace de puente entre la aplicacion cliente y un objeto en
 * el servidor NetIO.
 * \return 
 */
function __object( cSession, cObjId, cMsg, ... )

   local aPubMsgs
   local aMsgs
   local lData
   local nPCount
   local uReturn
   local oTmpObj
   local cClassName
   
#ifdef __DEBUG__
  tracelog LINE
  tracelog ""
  tracelog "cSession  = ",cSession
  tracelog "cObjId = ",cObjId
  tracelog "cMsg   = ",cMsg
#endif

   default cSession  to ""
   default cObjId to ""
   default cMsg   to ""
   
   if Empty( cObjId ) ; return NIL ; endif
/*
   cSession  := hb_pValue(1)
   cObjId := hb_pValue(2)
   cMsg   := hb_pValue(3)
*/   
   if Empty(cSession)
      aPubMsgs := __objGetMsgList( oAcc )
   else
      if !oApp:oSession:IsDef( cSession ) ; return NIL ; endif
      aPubMsgs := __objGetMsgList( oApp:oSession:Get( cSession ) )
   endif

   /* Verificamos que el objeto esta registrado en oAcc */
/*
   if AScan( aPubMsgs, { |element| element = cObjId } ) = 0
      tracelog "elemento ["+ cObjId +"] No encontrado en oAcc..."
      return NIL
   endif
*/

   debug "Valor del parametro 1 = ",hb_pValue(1)
   
   /* Buscamos si el segundo parametro es un Data o Metodo */
   nPCount := PCount()
   
   if nPCount < 3 ; return NIL ; endif
   
   debug "cObjId ", cObjId   

   lData := iif(nPCount = 3, .t., .f. )
   
   //aMsgs := __objGetMsgList( oAcc:Get( cObjId ), lData )
   aMsgs := GetMsgsList( cSession, cObjId, lData )
   
#ifdef __DEBUG__
   tracelog "Mensajes " 
   tracelog hb_ValtoExp( aMsgs )
#endif
  
//   cPar := hb_pValue(3)

   if AScan( aMsgs, { |element| element = Upper( cMsg ) } ) = 0

      debug "[", hb_pValue(3), "] No encontrado. "
    
      //aMsgs := __objGetMsgList( oAcc:Get( cObjId ), !lData )
      aMsgs := GetMsgsList( cSession, cObjId, !lData )
      debug hb_ValToExp( aMsgs )

//tracelog hb_Valtoexp( aMsgs )
//AEVAL( aMsgs,{|a| QOUT( a ) } )
      //if AScan( aPubMsgs, { |element| element = cMsg } ) = 0
      if AScan( aPubMsgs, { |element| element = cMsg } ) = 0
//tracelog "["+cMsg+"] No encontrado. ",CRLF

         /* Buscamos dentro de hVars si es un objeto tpublic */
         if cObjId != "oAcc" 

#ifdef __DEBUG__
  tracelog LINE
  tracelog " El Objeto ["+cObjId+"] Posiblemente Pertenece a subObjeto ["+cSession+"]"
  tracelog " Es posible que el dato se encuentre dentro de un Hash de una Instancia TPublic o DBServer. "
  tracelog LINE
#endif

            if AScan( aMsgs, {|element| element = "ISDEF" } ) = 0 
debug "Ido.. no se reconoce el objeto "
               return nil
            endif
debug " Ejecutando oAcc:Isdef("+cObjId+") ", oApp:oSession:IsDef(cObjId) 
            oTmpObj := oApp:oSession:Get( cObjId )
            if hb_IsNIl( oTmpObj )
debug "El objeto no pertenece a oApp:oSession... debe ser oAcc:cSession"
               oTmpObj := oApp:oSession:Get(cSession):Get(cObjId)
               if !hb_IsNil( oTmpObj )
                  uReturn := __objSendMsg( oTmpObj, cMsg )

debug "Obj: [",Alltrim( cObjId ),"]   ",;
         "Msg [",cMsg,"]  ", hb_eol(), Repl("=",30), hb_eol()
                  return Value2Remote( uReturn )
               else
debug "Nada que hacer... hasta aqui nos trajo el río."
                  return nil
               endif
            endif
            cClassName := oTmpObj:ClassName()

debug "Instancia de Clase: ",cClassName

            if cClassName="TPUBLIC" .or. cClassName="DBSERVER" .or. cClassName="DBUSER"

#ifdef __DEBUG__
  tracelog " es Instancia de TPublic "
  tracelog " El Mensaje es ",cMsg
#endif
               if oTmpObj:IsDef( cMsg )
#ifdef __DEBUG__
  tracelog " Esta Definido... ", cMsg
  tracelog oTmpObj:Get( cMsg )
  tracelog LINE
#endif
                  return Value2Remote( oTmpObj:Get( cMsg ) )
               endif
//            else
//#ifdef __DEBUG__
//  tracelog "Contenido de hVars en oAcc "
//  tracelog hb_valtoexp( oAcc:GetArray() )
//#endif
            else
debug "Clase: "+cClassName+"  Mensaje = "+cMsg
               uReturn := __objSendMsg( oTmpObj, cMsg )
#ifdef __DEBUG__
  tracelog "Valtype de retorno "+ValType(uReturn)
  tracelog "Valor "+hb_ValToExp( uReturn )
#endif
               return Value2Remote( uReturn )
            endif
         endif

         return NIL
      endif
      
   else  // Encontrado
   
      if lData 
         // retornamos el valor del data solicitado.
         //tracelog cPar, ValToPrg(hb_ExecFromArray( oAcc:Get( cObjId ) , cPar ))
         /*
         uReturn := hb_ExecFromArray( oAcc:Get( cObjId ),;
                                  cMsg )
         */
         if cObjId = "oAcc"
            uReturn := __objSendMsg( oAcc, cMsg )
         else
            uReturn := __objSendMsg( oApp:oSession:Get( cObjId ), cMsg )
         endif

         debug "Obj: [",Alltrim( cObjId ),"]   ",;
               "Msg [",cMsg,"]  ", hb_eol(), Repl("=",30), hb_eol()

         return Value2Remote( uReturn )
      endif
   endif

debug "__Object(). Revisar..."
return nil




/* Retorna arreglo con lista de mensajes o metodos de un objeto segun sea el caso. */
static function GetMsgsList( cSession, cObjId, lData, cType )
   local aMsgs := {}
   local oObj

   // cType = "D" or "M"
   default cType to "D"
   default cSession to ""

   if Empty( cObjId ) ; return aMsgs ; endif

   if cObjId = "oAcc"
      if cType = "M"
         aMsgs := __objGetMethodList( oAcc )
      else
         aMsgs := __objGetMsgList( oAcc, lData )
      endif

   elseif cSession==cObjId
//tracelog "cSession es igual a cObjId => ["+cSession+" = "+cObjId+"]"
      if oApp:oSession:IsDef(cSession)
         if cType = "M" 
            aMsgs := __objGetMethodList( oApp:oSession:Get(cSession) )
         else
            aMsgs := __objGetMsgList( oApp:oSession:Get(cSession), lData )
         endif
      endif
   else

      if !Empty(cSession)
         oObj := oApp:oSession:Get( cSession )
debug "oObj debe ser oApp:oSession:Get('"+cSession+"')"
      else
         oObj := oAcc
debug "oObj ahora es oAcc..."
      endif

debug " oOBJ =>  "+oObj:ClassName()
      if !hb_IsObject( oObj ) ; return {} ; endif

      if oObj:IsDerivedFrom("TPUBLIC") .and. !oObj:IsDef( cObjId ) 
debug "No esta definido "+cObjId+" en oAcc"
         return nil 
      endif

      if cType = "M"
         aMsgs := __objGetMethodList( oObj )
      else
         aMsgs := __objGetMsgList( oObj, lData )
      endif
      
   endif
return aMsgs


/** Recibe un objeto y nombre de un metodo a ejecutar de ese objeto, 
 *  retorna lo obtenido.
 */
function __ObjMethod( cSession, cObjId, cMethod,... )

   local aPubMsgs
   local aMsgs, aParams:={}, nParam := 4, cParams, uParam
   local lData
   local nPCount
   local uReturn
   local cName
   local oObj

   debug "Sesion:[", cSession, "] Objeto:[", cObjId, "] Metodo:[",cMethod,"]", ...
   
   default cSession to "", cObjId to "",  cMethod to ""

   if Empty( cObjId ) ; return NIL ; endif

   aPubMsgs := __objGetMsgList( oAcc )

   
   nPCount := PCount()
   
   if nPCount < 3 ; return NIL ; endif

//tracelog "cSession => ", cSession,"  cObjId =>  ", cObjId, " valtype( ", ValType( cObjId ), " )" 
   aMsgs := GetMsgsList( cSession, cObjId, , "M" )
   
   if aMsgs = NIL 
      tracelog " No existe ["+cObjId+"]"
      return NIL 
   endif

   aParams := ARRAY( nPCount - 3 )
   FOR EACH uParam IN aParams
      uParam := hb_pValue( uParam:__EnumIndex() + 3 )
   NEXT
//tracelog "++++++++++++++++++ ++++++++++ +++++++ +++ ++"
//tracelog nPCount, " parametros: "
//tracelog hb_valtoexp( aParams )
//tracelog "++++++++++++++++++ ++++++++++ +++++++ +++ ++"

//   tracelog "Total de Parametros reales: ", LEN(aParams)
//?

/*
   if cObjId = "oAcc"
//   ?? "Obj: [",Alltrim( cObjId ),"]  ClassName:[", AllTrim(oAcc:ClassName()),"] "
   else
//tracelog "Objeto ",cObjId," "
      if oAcc:IsDef(cObjId)
//      ?? "Obj: [",Alltrim( cObjId ),"]  ClassName:[", AllTrim(oAcc:hVars[cObjId]:ClassName()),"] "
      endif
   endif
*/

/*
//tracelog  "Method: [",cMethod,"]  ",hb_eol(),"Parametros restantes: ", nPCount-3
   if !Empty(aParams)
//tracelog hb_valtoexp( aParams )
//tracelog LINE
//      AEVAL( aParams, {|param,n| QOUT("| par",AllTrim(hb_valtoexp(n))," : ",param) } )
//tracelog LINE
   endif
*/

   if Empty(aParams)
      //uReturn := hb_ExecFromArray( oAcc:Get( pValue(1) ), cPar )

/**
 *   OJO - Aquí, ya no debe usar objeto oAcc, debe usar el identificador de la sesion.
 *
 */
      if cObjId = "oAcc"
         if !( UPPER(cMethod) $ "SERVERLOGIN,SALUDA,INCLIST,INCGET,SCRIPTLIST,SCRIPTGET,"+;
                                "RESOURCELIST,RESOURCEGET,IMAGELIST,IMAGEGET" )
            tracelog "ATENCION. El metodo ", cMethod, " No forma parte de los metodos permitido. "
            return Value2Remote("")
         endif
         debug "Solicitando al objeto publico:", cObjId, "Metodo:", cMethod
         uReturn := __ObjSendMsg( oAcc, cMethod )
      else
         //uReturn := __ObjSendMsg( oAcc:Get( cObjId ), cMethod )
         if Empty(cSession)
            if UPPER( cMethod )="LOGOUT"
               debug "Metodo solicitado. ",cMethod
               return Value2Remote("")
            endif
            TRY
               uReturn := __Execute( oApp:hVars[ cObjId ], cMethod )
            CATCH
               tracelog "ATENCION: Problema al solicitar el metodo",cMethod 
            END
         else
            TRY
               if cObjId=cSession
//tracelog "Objeto: ["+cObjId+"]   => Clase: "+oApp:oSession:hVars[cSession]:ClassName()
                  uReturn := __Execute( oApp:oSession:hVars[cSession], cMethod )
               else
//tracelog "Objeto: ["+cObjId+"]   => Clase: "+oApp:oSession:hVars[cSession]:hVars[cObjId]:ClassName()
                   uReturn := __Execute( oApp:oSession:hVars[cSession]:hVars[cObjId], cMethod )
               endif
            CATCH
               #ifdef __DEBUG__
                  tracelog MSG_LINE
                  tracelog "-- ERROR AL INTENTAR EJECUTAR --"
                  tracelog "Sesion:", cSession, " cObjId:", cObjId," Metodo:", cMethod
                  tracelog MSG_LINE
               #endif
               if !oApp:oSession:IsDef( cSession )
                  uReturn := tpy_message( 100, "valor no reconocido" )
                  return Value2Remote( uReturn )
               endif
            END
         endif
      endif
      
   else
//tracelog "Object ------ >  ", hb_valtoexp(oAcc:hVars[ cObjId ])
//tracelog hb_valtoexp(aParams)
      if cObjId = "oAcc"
tracelog "invocando en oAcc... cSession = ",cSession,"  Metodo = ", cMethod
         // -- Aca atrapamos el metodo.. si es logout solo puede hacer logout el propio usuario.
         //    No debe hacer logout a otro usuario...  (RIGC)
         if UPPER(cMethod)=="SERVERLOGOUT"
tracelog "NO PUEDE SER!!!!!!"
            uReturn := __Execute( oAcc, cMethod, {cSession} )
         else
            uReturn := __Execute( oAcc, cMethod, aParams )
         endif
      else
         if Empty(cSession)
//tracelog "empty cSession"
tracelog "ATENCION. Usuario sin sesion solicitando ejecutar ",cMethod
tracelog "cObjId:",cObjId," cMethod:",cMethod
tracelog MSG_LINE
            uReturn := __Execute( oAcc:Get[ cObjId ],;
                                         cMethod, aParams )
         else
//tracelog "no empty cSession"
//tracelog "hVars: "
//tracelog hb_ValToExp( oAcc:hVars[cSession]:hVars )
//tracelog LINE
//tracelog hb_valToExp( aParams )
            //uReturn := hb_ExecFromArray( oAcc:hVars[cSession]:hVars[ cObjId ],;
            if !oApp:oSession:IsDef(cSession) 
               uReturn := nil
            else
               if cSession = cObjId
tracelog "oApp:oSession:cSession es tipo "+oApp:oSession:hVars[cSession]:ClassName()
                  uReturn := __Execute( oApp:oSession:Get[ cObjId ],;
                                               cMethod, aParams )
               else
//tracelog "oAcc:cSession:cObjId es tipo "+oAcc:hVars[cSession]:hVars[cObjId]:ClassName()
tracelog "ATENCION  REVISAR ESTE PUNTO... "
tracelog "tpy_messages"
tracelog "cSession:",cSession, "  cObjId:",cObjId,"  cMethod:",cMethod
tracelog MSG_LINE
                  uReturn := __Execute( oAcc:Get[cSession]:Get[ cObjId ],;
                                               cMethod, aParams )
               endif
            endif
         endif
      endif
//      uReturn := __ObjSendMsg( oAcc, cMethod, aParams  )
//      uReturn := __ObjSendMsg( oAcc:Get( cObjId ), cMethod, aParams  )
/*                                 
      cParams := ARRAY2CSV(aParams)
      cParams := LEFT(cParams, LEN(cParams)-1)
      cParams := RIGHT(cParams, LEN(cParams)-1)
      
      uReturn := __ObjSendMsg( oAcc:Get( pValue(1) ), cObjId, &cParams )
*/
   endif

//tracelog "tipo de retorno ",ValType(uReturn)
//tracelog hb_valtoexp(uReturn)
   
   cName := hb_pValue( 4 )

   // funciones no permitidas en el objeto publico oAcc retornan vacio
   if cObjId = "oAcc" .and. UPPER(cMethod) $ "GETARRAY" 
      debug "Detectado llamado a ", cMethod, "  RETORNAMOS Vacio. "
      return Value2Remote("")
   endif
   if cObjId = "oAcc" .and. cMethod = "ServerLogin" .and. ValType( cName ) = "C"

      debug "Procedemos a buscar ", cName, " en oApp "

      //#TODO: Verificamos si el usuario tiene una sesion abierta. De ser asi, 
      //       se debe eliminar y reiniciar la sesion.
      if oApp:oSession:IsDef( cName )
         debug "El objeto [",cName,"] es tipo [",oApp:oSession:Get(cName):ClassName(),"]"
         oApp:oSession:Del( cName )

         debug "El Objeto ["+cName+"] ya estaba registrado, por lo que ha sido liberado de memoria. "

      endif

   else
      cName := StrTran( DtoC( hb_DateTime() ), "/", "" )
      cName += StrTran( AllTrim( Str( Seconds() ) ), ".", "" )
      //cName := StrTran( AllTrim( cName  ), ".", "" )

   endif
   
   if hb_IsObject( uReturn )
      if Empty(cSession)
         // -- Se ha retornado un objeto, se registra ese objeto.
         cName := hb_MD5( "tpy"+cName+DTOC(DATE()) )
//tracelog "Registrando... cName, valor = ", cName
/**  Esto ya no sería necesario... el objeto ya fue registrado en el proceso de login. RIGC 2019-07-07
         tracelog "<PENDIENTE>  Este identificador, debe ser registrado en el objeto de la sesion abierta del usuario "
         oAcc:Add( cName, uReturn )
*/
      else
         oObj := oAcc:oSession:Get(cSession)
         if hb_IsNIL( oObj )
            tracelog " Objeto NULO, retornamos vacio. "
            return Value2Remote("")
         endif
         oObj:Add( cName, uReturn )
      endif
//tracelog "registrado objeto ["+cName+"] en "+cObjId,CRLF,Repl("=",30),CRLF
//tracelog "Objeto: ",cObjId
//tracelog "Metodo: ",cMethod
//tracelog "Retorno: ",uReturn:ClassName()
//tracelog "Nro de Variables en App: ",LEN( oAcc:hVars )
//AEVAL( oAcc:GetArray() , {|a| QOUT( a[1] ) } )
//tracelog "++++++++++++++++++++++++++++++++++++++++++++++++"
//?
//   aMsgs := __objGetMethodList( oAcc:Get( cObjId ) )
      return Value2Remote( cName )
   else
//tracelog "Objeto: ",cObjId
//tracelog "Metodo: ",cMethod
//tracelog "No hay objeto como retorno..."
   endif
           
//   tracelog "convirtiendo valor a retornar..."                   
return Value2Remote( uReturn )



static function __Execute( ... )

   local uRet

   TRY
      uRet := hb_ExecFromArray( ... )
   CATCH
#ifdef __DEBUG__
      tracelog MSG_LINE
      tracelog "Problema al intentar una ejecucion. "
      tracelog ...
      tracelog MSG_LINE
#endif
      uRet := NIL
   END

return uRet

     
/*
 Esta funcion da problemas cuando hay DATA Protegida
procedure tpy_release(oObj)
   #include "hboo.ch"
   if hb_IsObject( oObj )
      tracelog "Intentando eliminar los DATA del objeto."
      AEVAL( __objGetValueList( oObj ), ;
           {|a| iif( hb_IsObject(a[HB_OO_DATA_VALUE]), ;
                     tpy_release(a[HB_OO_DATA_VALUE]), ;
                     __objSendMsg( "_"+a[HB_OO_DATA_VALUE], nil ) )  } )
   endif
return
*/


//eof
