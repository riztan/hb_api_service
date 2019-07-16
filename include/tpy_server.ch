/**
 *  Llamados a cabeceras generalemente utilizadas
 *
 */

#include "netio.ch"
#include "common.ch"
#ifdef __MYSQL__
   #include "tdolphin.ch"
#endif
#include "hbcompat.ch"

#xtranslate tracelog <xValues, ...> => tps_Log( 0, procname(), procline() , <xValues> )

#xtranslate debug <xValues, ...> => tps_Log( 1, procname(), procline(), <xValues> )

#xtranslate tracelog LINE => QOUT( Repl("-",30) )

#define MSG_LINE REPLICATE("-",50)

#define CRLF   ( Chr( 13 ) + Chr( 10 ) ) //hb_eol()
//#define CR_LF                   ( Chr( 13 ) + Chr( 10 ) )


