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

#include "netio.ch"
 

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


/* TPuy */

#xtranslate ~HGet(<!func!>([<params,...>])) => ;
            hb_deserialize(netio_funcexec( #<func> [,<params>] ))
             


//eof

