/** Example 
 */

#include "tpy_netio.ch"

STATIC rSession  // Id of Session (token) => Remote Object of TSession Class

#define USER      "test"
#define PASSWORD  "12345678"

procedure main()

  local cServer, nPort, cPass, lConnect
  local hSession, cKey := "Sarisariñama"
  local cSessionPass, hRes, hContent

  cServer := "localhost"
  nPort   := 2940
  cPass   := "topsecret"

  ? "Connecting to: ", cServer, " Port: ", nPort
  lConnect := netio_connect( cServer, nPort,, cPass )
  
  if lConnect
     ? "Connected! "
  else
     ? "No Connection! "
     return
  endif 

  cSessionPass := hb_crypt( PASSWORD , cKey ) 

  ? 
  ? "Try login user:", USER
  // ~ServerLogin()   Execute Method ServerLogin on Remote TACC Class.
  hRes := ~ServerLogin( USER, cSessionPass, "127.0.0.1" /*TODO# Detect IP*/ )

  hContent := hRes["content"]

  if !hb_isHash( hRes ) 
     ? "Problem or error"
     netio_Disconnect( cServer, nPort )
     return
  endif

  ? "it's ok? =>", hRes["ok"]
  if !hRes["ok"]
     ? "Error. ", hRes["error_id"]
     ? "Comment: ", hRes["message"]
  endif
  ? "Content. "
  ? hb_valToExp( hRes["content"] )
  

  rSession := hRes["content"]["session_id"]  // session_id  =>  id of remote object.

  ?
  ? "Session Id: ", rSession 
  ? "User Name: ", hContent["user_data"]["firstname"]+" "+hContent["user_data"]["lastname"]
  ? "email: ", hContent["user_data"]["email"]
  ?
  
//  ? "All message from server. " 
//  ? hb_eol(), hb_valToExp( hRes )
//  ?

  ? "Invoking the help() method on server... "+;
    "( similar to:  https://"+cServer+":8001"+"/"+rSession+"?help )"
  ? ~~rSession:help()  //  execute on remote object the help() method.

  ~~rSession:Logout()

  ?
  ? "Finish. Sorry for my bad english."


  netio_Disconnect( cServer, nPort )
return




function FromRemote( cFuncName, cObj, ... )
   local uValue, cValtype, uReturn

   if hb_pValue(1) = nil ; return nil ; endif

   if !Empty(rSession)

      if UPPER(cObj) == "OSERVER" ; cObj := rSession ; endif

      uReturn := hb_deserialize( netio_funcexec( cFuncName, rSession, cObj, ...  ) )
   else

      uReturn := hb_deserialize( netio_funcexec( cFuncName, "", cObj, ...  ) )
   endif

return uReturn 

//eof
