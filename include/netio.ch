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





