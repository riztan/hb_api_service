/** TPuy Server
 *  tuser.prg   Clase TUser muy básica (sustituible) destinada 
 *              con la gestión de usuarios en el servidor.
 * 
 */

#include "tpy_server.ch"
#include "hbclass.ch"



CLASS TUSER

protected:
   DATA lastlogin
   DATA hData

   DATA hUsers  INIT {;
                     "riztang" => ;
                             {"firstname" => "Riztan Ivan",          ;
                              "shortname" => "Riztan",               ;
                              "lastname"  => "Gutierrez Carrero",    ;
                              "email"     => "riztan@gmail.com"      ;
                             },;
                     "javierp" => ;
                             {"firstname" => "Javier Parada",        ;
                              "shortname" => "Javier",               ;
                              "lastname"  => "Peña Nieto",           ;
                              "email"     => "jparada_a@hotmail.com" ;
                             },;
                     "tulioj" => ;
                             {"firstname" => "Tulio Jaimes",         ;
                              "shortname" => "Tulio",                ;
                              "lastname"  => "Puro Navas",           ;
                              "email"     => "jaimes.ta@gmail.com"   ;
                             },;
                     "onielr" => ;
                             {"firstname" => "Oniel Ajedrez",        ;
                              "shortname" => "Oniel",                ;
                              "lastname"  => "Revilla Python",       ;
                              "email"     => "eniolw@gmail.com"      ;
                             };
                     }

exported:
   METHOD New( cLogin )
   METHOD GetData()          INLINE ::hData
   
   ERROR HANDLER OnError()

ENDCLASS


METHOD OnError()  CLASS TUSER
   local hResp

   hResp := tpy_message( 100, "mensaje no reconocido" )

RETURN hResp


METHOD New( cLogin ) CLASS TUSER
   local aUsers := {"riztang","javierp","tulioj","onielr"}

   if ASCAN( aUsers, {|user| user==cLogin } )=0
      return nil
   endif

   ::hData := hb_hGet( ::hUsers, cLogin )

RETURN Self

//eof
