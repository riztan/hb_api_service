/** TPuy Server
 *  tcontrol.prg  Clase del objeto principal de control de la aplicacion en
 *                el servidor.
 *                El objeto principal en el servidor (oApp) es instancia de 
 *                esta clase
 */

/**
 *
 */
CLASS TCONTROL FROM TPUBLIC

protected:
   DATA oNewUser       // Identificador de usuario a registrar
   DATA cConnDefault   INIT ""
   DATA oLServer
   DATA oConn

   METHOD ObjFree( cObjId )         INLINE  tps_free( cObjId )
   METHOD End()                     INLINE ( /*::oLServer:End(),*/ ::oEnd() )

exported:
   DATA lError         INIT .f.
   DATA cError         INIT ""

   DATA oFAttemps      
   DATA oSession

   METHOD New()  //INLINE Super():New()

   /* Dejamos el metodo CheckUser() en archivo externo "checkuser.prg" 
      de manera que sea intercambiable. Es decir, la verificación de 
      usuario sea de acuerdo a como cada se considere apropiado en cada
      proyecto individual. Se incluye una versión muy básica del mismo.
   */
   METHOD CheckUser( cLogin, cPass )   //INLINE   .T.  // Debe verificar si los datos del usuario 
                                                     // (login, clave, etc) son correctos.

   METHOD Saluda()    INLINE "HOLA! Soy el metodo Saluda() de la clase TCONTROL !!!!"   


ENDCLASS



METHOD NEW() CLASS TCONTROL
   ::Super:New()

   /*
    #TODO:   Crear conexión a base de datos del Servidor (TPuy)
   */

   /*
    #TODO:   Crear objeto o registro de control de intentos fallidos de ingreso al sistema.
   */
   ::oFAttemps := TPublic():New() //-- Objeto contenedor de fallidos intentos de inicio de sesion 

   ::oSession  := TPublic():New() //-- Objeto contenedor de las sesiones abiertas.


   /*
    #TODO:   Crear objeto que controla las sesiones activas
   */

   tracelog "De momento no hay conexion a base de datos configurada... "  
   ::oLServer := NIL //DBServer():New("pg","pg_tpy")
   if ::oLServer=NIL
      tracelog "No hay conexion."
      Return self // de momento retornamos self, pero debería usarse al menos una conexion a BD.
   endif

   /*

   ::cConnDefault := ::oLServer:cConnDefault
   ::oConn := ::oLServer:GetConn(::cConnDefault) //:oConn
   tracelog "Conexion por defecto de oAcc. ::oConn = ", ::oConn:ClassName()

//? procname(),": verificando conexion..."
   if !::Check_Connection( ::oLServer )
//? procname(),": Fallo verificacion de la conexion. nos vamos... "
      debug "Fallo la verificación de la conexion."
      return nil
   endif

   */

RETURN SELF



/* Check users data. Change this method to the corresponding one for 
                     your personal application
 */
METHOD CheckUser( cLogin, cPass ) CLASS TCONTROL
   Local hUsers := hb_hash(), lResp := .f.
   
   default cLogin to ""

   hUsers := { ;
               "test"    => "12345678",;
               "riztang" => "01020304",;
               "javierp" => "04030201",;
               "onielr"  => "14131211" ;
             } 

   if hb_hHasKey( hUsers, cLogin ) 
      if "tpy"+hUsers[cLogin]+"123" == cPass 
         lResp := .t.
      else
debug "User no found",cLogin
debug cpass
      endif
   endif


RETURN lResp



/** Libera un objeto de oAcc
 *
 */
static procedure tps_Free( cObjName )
//tracelog "Intentando Liberar de memoria el objeto ",cObjName
   if hb_IsNil(cObjName) ; return ;  endif

   if oAcc:IsDef( cObjName )
      tracelog "Deleting " + cObjName
      //tpy_release( oAcc:Get( cObjName ) )
      oAcc:Del( cObjName )
//tracelog "Aparentemente Liberado el objeto ",cObjName
//tracelog "Nro de Variables en App: ",LEN( oAcc:hVars )
//AEVAL( oAcc:GetArray() , {|a| QOUT( a[1] ) } )
//tracelog "=============================================="
   endif
return


//eof
