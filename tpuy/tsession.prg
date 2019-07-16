/** TPuy Server
 *  tsession.prg  Clase para el control de la sesion en el servidor
 *
 */

CLASS TSESSION FROM TPUBLIC

   DATA cUserId

   METHOD New( cId, cUser, cId )

   METHOD UserData()
   METHOD LogOut()  INLINE oApp:oSession:Del( ::cId )

   METHOD Help()    INLINE "Hola. Esta es la calse TSession. A través de esta, puedes obtener "+;
                           "información de tu sesion abierta. "+;
                           "Algunos metodos disponibles "+CRLF+;
                           "UserData() -> Retorna los datos básicos del usuario en esta sesion. "+CRLF+;
                           "Logout()   -> Finaliza esta sesión. "

ENDCLASS


METHOD NEW( cId, cUser, cIp )  CLASS TSESSION

   ::Super():New()

   ::cId   := cId
   ::cUser := cUser
   ::cIp   := cIp

Return SELF


/**  El usuario debería retornar de una clase usuario. (RIGC 2019-07-15)
 *
 */
METHOD UserData() CLASS TSESSION

   local hUser //, hResp 
   local oUser

   oUser := TUSER():New( ::cUser )

   hUser := oUser:GetData() //hb_Hash()

RETURN hUser


//eof
