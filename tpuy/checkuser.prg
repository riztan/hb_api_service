/** TPuy Server 
 *  checkuer.prg   rutina sustituible destinada a la verificación de datos de usuario.
 *  
 */


METHOD CheckUser( cLogin, cPass ) CLASS TCONTROL
   Local hUsers := hb_hash(), lResp := .f.
   
   default cLogin to ""

   hUsers := { ;
               "riztang" => "01020304",;
               "javierp" => "04030201",;
               "tulioj"  => "11121314",;
               "onielr"  => "14131211" ;
             } 

   if hb_hHasKey( hUsers, cLogin ) 
      if "tpy"+hUsers[cLogin]+"123" == cPass 
         lResp := .t.
      else
debug "no encontrado",cLogin
debug cpass
      endif
   endif


RETURN lResp

//eof
