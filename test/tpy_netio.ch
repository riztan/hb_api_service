/*
 * $Id: client.prg 2011-12-28 17:26 riztan $
 */

/*
 *
 * Copyright 2010 Przemyslaw Czerpak <druzus / at / priv.onet.pl>
 * www - http://harbour-project.org
 *
 */
/*
 * Modificaciones por Riztan Gutierrez. <riztan / at / gmail.com>
 */

#xtranslate net:<!func!>([<params,...>]) => ;
            netio_funcexec( #<func> [,<params>] )
#xtranslate net:[<server>]:<!func!>([<params,...>]) => ;
            netio_funcexec( [ #<server> + ] ":" + #<func> [,<params>] )
#xtranslate net:[<server>]:<port>:<!func!>([<params,...>]) => ;
            netio_funcexec( [ #<server> + ] ":" + #<port> + ":" + #<func> ;
                            [,<params>] )


#xtranslate net:exists:<!func!> => ;
            netio_procexists( #<func> )
#xtranslate net:exists:[<server>]:<!func!> => ;
            netio_procexists( [ #<server> + ] ":" + #<func> )
#xtranslate net:exists:[<server>]:<port>:<!func!> => ;
            netio_procexists( [ #<server> + ] ":" + #<port> + ":" + #<func> )


#xtranslate ~<!msg!>[(<params,...>)] => ;
            FromRemote( "__object", "oAcc", #<msg>[, <params>] )

#xtranslate ~<!method!>([<params,...>]) => ;
            FromRemote( "__objmethod", "oAcc", #<method>[, <params>] )


#xtranslate ~<!object!>:<!msg!>[(<params,...>)] => ;
            FromRemote( "__object", #<object>, #<msg>[, <params>] )

#xtranslate ~<!object!>:<!method!>([<params,...>]) => ;
            FromRemote( "__objmethod", #<object>, #<method>[, <params>] )



#xtranslate r:<object>:<!msg!> => ;
            FromRemote( "__object", <object>, #<msg> )

#xtranslate r:<object>:<!method!>([<params,...>]) => ;
            FromRemote( "__objmethod", <object>, #<method>[, <params>] )

#xtranslate ~~<object>:<!msg!>[(<params,...>)] => ;
            FromRemote( "__object", <object>, #<msg>[, <params>] )

#xtranslate ~~<object>:<!method!>([<params,...>]) => ;
            FromRemote( "__objmethod", <object>, #<method>[, <params>] )

#xtranslate GET <uValue> FROM QUERY <object> => FromRemote( "__objmethod",<object>,#<uValue> )

#xtranslate ~get(<object>:<uValue>) => FromRemote( "__objmethod",<object>,#<uValue> )

#xtranslate rDbServer:New(<!object!>) => ;
            netio_funcexec( "db_connect", #<object> )



//eof

