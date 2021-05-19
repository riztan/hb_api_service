/*
 * $Id: netio_srv.prg 2012-09-17 14:53 riztan $
 */
/*
 * Harbour Project source code:
 *    demonstration/test code for alternative RDD IO API which uses own
 *    very simple TCP/IP file server.
 *
 * Copyright 2009 Przemyslaw Czerpak <druzus / at / priv.onet.pl>
 * www - http://harbour-project.org
 *
 */

/* \file netio_srv.prg 
 * \brief Archivo Inicial - Servidor NetIO.
 * Inicia un servicio tipo NetIO de Harbour.
 * \details
 * Crea un objeto TPublic que es accesible desde el cliente.
 * Incorpora la posibilidad de crear una conexion a MySQL usando TDolphin.
 *
 * La intención de este programa es ofrecer la posibilidad de crear aplicaciones 
 * livianas que no realicen conexiones directas a la base de datos para reducir
 * la carga en el servdor. 
 * Adicionalmente centralizar las acciones de control en el servidor como tal.
 * Un ejemplo del trabajo podría ser el hecho de generar algo similar a los triggers
 * en el servidor de NetIO de manera que en la aplicación cliente eso sea transparente.
 *
 * \date 2019 
 * \author Riztan Gutierrez <riztan / at / gmail . com>
 *
 */

#include "connect.ch"

/** \var oAcc          Instancia de (TAcc)
 *  \var oApp          Instancia de Control (TApp) 
 */
//memvar nTime, oAcc, oApp //oDbServer
static oAcc, oApp
memvar nTime
static hMutex

#include "tpy_server.ch"

#include "tpuy/tpy_messages.prg"
#include "tpuy/tpy_serv.prg"
#include "tpuy/tacc.prg"


/** \brief Procedimiento Princial. */
procedure Main()
   local pSockSrv, lExists, cValue

   nTime := 15

   SET( _SET_DATEFORMAT, "yyyy/mm/dd" )

   tps_Welcome()
   ?
   /* Creamos el Objeto Publico */

   tracelog "Creando objeto de acceso publico [oAcc]"

   oAcc := TAcc():New()
   if hb_IsNIL( oAcc ) 
      debug "No ha podido ser creado el objeto oAcc. Nos vamos!"
      netio_serverstop( pSockSrv, .t. )
      return 
   endif
   #ifdef __HELP__
      tracelog "El objeto oAcc es utilizado exclusivamente para proveer ", hb_eol(), ;
      "               metodos de entrada al servidor (la puerta de entrada) " 
   #endif

   //-- Creación del objeto de control principal de la aplicación.
   oApp := TControl():New()

   if hb_IsNIL( oApp )
      tracelog "El objeto oApp no se ha podido crear. No es posible continuar."
      return
   endif

   
   //-- Iniciamos los servicios.

   pSockSrv := tpuy_mtserver( NETPORT,,, /* RPC */ .T., NETPASSWD )

   if empty( pSockSrv )
      tracelog "Cannot start NETIO server !!!"
      //wait "Press any key to exit..."
      quit
   endif


   tracelog "Servicio API  (NetIO) Iniciado."
   tracelog "Puerto", NETPORT
   


   //--  Iniciamos servicio web.
   #ifdef __WEBSERVICE__
     tracelog "Iniciando Servicio Web."
     hb_threadDetach( hb_threadStart( @hb_webserver() ) )
   #endif


   hb_idleSleep( 0.1 )
   wait

//   tracelog "NETIO_DISCONNECT():", netio_disconnect( DBSERVER, DBPORT )
   end_service( pSockSrv )

return


Procedure end_service( pSockSrv )
   tracelog "stopping the server..."
   netio_serverstop( pSockSrv, .t. )
   
   //-- Cerrar las sesiones en oApp
   if hb_IsObject( oApp )
      debug "Cerrando Objeto de control (oApp)..."
      oApp:End()
   endif

   tps_End()
RETURN



/** \brief Verifica que la conexión <i>oConnection</i> ha sido creada.
    Igualmente si no hay conexión predeterminada, la asigna.
 */
Function CHECK_CONNECTION( oConnection, oAcc )

   if !hb_IsObject( oConnection )
      Alert("No se ha podido crear objeto [Connection]")
      return .f.
   else
      if Empty( oAcc:oLServer:cConnDefault )
         oAcc:oLServer:SetDefault( oConnection )
      endif
   endif

Return .t.




FUNCTION FromRemote( cFuncName, cSession, cObj, ... )
   local uReturn, uContent

debug "Funcion:", cFuncName, " Sesion:",cSession," Obj:", cObj, ...

   if hb_pValue(1) = nil ; return nil ; endif
   TRY 
      if empty( cSession ) .or. UPPER(cSession) = "OACC"
         uReturn := netio_funcexec( cFuncName, "", cSession, cObj, ...  )
      else
         tracelog cSession, cObj
         uReturn := netio_funcexec( cFuncName, cSession, cSession,cObj, ...  )
      endif
//debug hb_valToExp( uReturn )
      uContent := hb_deserialize( uReturn )
      uReturn := tpy_Message( 0, "", uContent )
   CATCH
      tracelog "Problemas al ejecutar ",cFuncName, cSession, cObj
      //uReturn := hb_deserialize( nil )
      uReturn := tpy_message( 500 ) //"problema desconocido"
   END
   if hb_IsHash( uContent ) //.and. hb_hHasKey( uContent, "ok" )
      return uContent 
   endif
debug "Recibido ", hb_ValtoExp( uReturn )
return uReturn //hb_deserialize( netio_funcexec( ... ) )



FUNCTION tpy_message( nId, cMsg, uContent, cType )
   local hMessage, cFormat := ""

   default cType to "unknow"

   if Empty(cMsg) .and. nId>0
      cMsg := err_msg( nId )
   endif

   if cType = "unknow"
      cType := VALTYPE( uContent )
      Do Case
      Case cType="C"
         cType := "string"
      Case cType="N"
         cType := "numeric"
      Case cType="D"
         cType := "date"
      Case cType="T"
         cType := "date_time"
      Case cType="L"
         cType := "boolean"
      Case cType="A"
         cType := "array"
      Case cType="H"
         cType := "hash"
      Other
         cType := "unknow"
      EndCase
   endif 

   hMessage := {                              ;
                 "ok" => iif( nId=0,.t.,.f.), ;
                 "error_id" => nId,           ;
                 "message"  => cMsg,          ;
                 "type"     => cType,         ;
                 "content"  => uContent       ;
               }
RETURN hMessage




#include "error.ch"

FUNCTION tpuy_MTServer( nPort, cIfAddr, cRootDir, xRPC, ;
                         cPasswd, nCompressLevel, nStrategy, ;
                         sSrvFunc )

   LOCAL pListenSocket, lRPC
   LOCAL oError

   IF sSrvFunc == NIL
      sSrvFunc := @netio_Server()
   ENDIF

   IF hb_mtvm()

      SWITCH ValType( xRPC )
      CASE "S"
      CASE "H"
         lRPC := .T.
         EXIT
      CASE "L"
         lRPC := xRPC
         EXIT
      OTHERWISE
         xRPC := NIL
      ENDSWITCH

      pListenSocket := netio_Listen( nPort, cIfAddr, cRootDir, lRPC )
      IF ! Empty( pListenSocket )
         hb_threadDetach( hb_threadStart( @tpuy_srvloop(), pListenSocket, ;
                                          xRPC, sSrvFunc, ;
                                          cPasswd, nCompressLevel, nStrategy ) )
      ENDIF
   ELSE
      oError := ErrorNew()

      oError:severity    := ES_ERROR
      oError:genCode     := EG_UNSUPPORTED
      oError:subSystem   := "HBNETIO"
      oError:subCode     := 0
      oError:description := hb_langErrMsg( EG_UNSUPPORTED )
      oError:canRetry    := .F.
      oError:canDefault  := .F.
      oError:fileName    := ""
      oError:osCode      := 0

      Eval( ErrorBlock(), oError )
   ENDIF

   RETURN pListenSocket



STATIC FUNCTION tpuy_SRVLOOP( pListenSocket, xRPC, sSrvFunc, ... )

   LOCAL pConnectionSocket//, hSocket, aSocket

   DO WHILE .T.
      pConnectionSocket := netio_Accept( pListenSocket,, ... )
      IF Empty( pConnectionSocket )
         EXIT
      ENDIF
// -- Lamentablemente esto aún no funciona. Se queda en pausa hasta que tenga ganas 
//    de volver a revisarlo.

//      hSocket := netio_GetSocket( pConnectionSocket )
//      aSocket := hb_socketGetPeerName( hSocket )
//      if !Empty( aSocket ) ; ? "Desde:", aSocket[2] ; endif
//      ? sSrvFunc, ...

      IF xRPC != NIL
         netio_RPCFilter( pConnectionSocket, xRPC )
      ENDIF
      hb_threadDetach( hb_threadStart( sSrvFunc, pConnectionSocket ) )

      pConnectionSocket := NIL
   ENDDO

   RETURN NIL



/*
#pragma BEGINDUMP
#include "hbapi.h"
#include "hbapiitm.h"
#include "hbapifs.h"
#include "hbapierr.h"
#include "hbsocket.h"
#include "hbstack.h"
#include "netio.h"


typedef struct _HB_CONSTREAM
{
   int id;
   int type;
   struct _HB_CONSTREAM * next;
}
HB_CONSTREAM, * PHB_CONSTREAM;


typedef struct _HB_CONSRV
{
   PHB_SOCKEX     sock;
   PHB_FILE       fileTable[ NETIO_FILES_MAX ];
   int            filesCount;
   int            firstFree;
   int            timeout;
   HB_BOOL        stop;
   HB_BOOL        rpc;
   HB_BOOL        login;
   PHB_SYMB       rpcFunc;
   PHB_ITEM       rpcFilter;
   PHB_ITEM       mutex;
   PHB_CONSTREAM  streams;
   HB_MAXUINT     wr_count;
   HB_MAXUINT     rd_count;
   int            rootPathLen;
   char           rootPath[ HB_PATH_MAX ];
}
HB_CONSRV, * PHB_CONSRV;


static void s_consrv_close( PHB_CONSRV conn )
{
   int i = 0;

   if( conn->rpcFilter )
      hb_itemRelease( conn->rpcFilter );

   while( conn->streams )
   {
      PHB_CONSTREAM stream = conn->streams;
      conn->streams = stream->next;
      hb_xfree( stream );
   }

   if( conn->mutex )
      hb_itemRelease( conn->mutex );

   if( conn->sock )
      hb_sockexClose( conn->sock, HB_TRUE );

   while( conn->filesCount > 0 )
   {
      if( i >= NETIO_FILES_MAX )
         break;   // internal error, it should not happen 

      if( conn->fileTable[ i ] )
      {
         hb_fileClose( conn->fileTable[ i ] );
         conn->filesCount--;
      }
      ++i;
   }

   hb_xfree( conn );
}


static HB_GARBAGE_FUNC( s_consrv_destructor )
{
   PHB_CONSRV * conn_ptr = ( PHB_CONSRV * ) Cargo;

   if( *conn_ptr )
   {
      PHB_CONSRV conn = *conn_ptr;
      *conn_ptr = NULL;
      s_consrv_close( conn );
   }
}

static HB_GARBAGE_FUNC( s_consrv_mark )
{
   PHB_CONSRV * conn_ptr = ( PHB_CONSRV * ) Cargo;

   if( *conn_ptr && ( *conn_ptr )->rpcFilter )
      hb_gcMark( ( *conn_ptr )->rpcFilter );
}


static const HB_GC_FUNCS s_gcConSrvFuncs =
{
   s_consrv_destructor,
   s_consrv_mark
};



static PHB_CONSRV s_consrvParam( int iParam )
{
   PHB_CONSRV * conn_ptr = ( PHB_CONSRV * ) hb_parptrGC( &s_gcConSrvFuncs,
                                                         iParam );

   if( conn_ptr && *conn_ptr )
      return *conn_ptr;

   hb_errRT_BASE_SubstR( EG_ARG, 3012, NULL, HB_ERR_FUNCNAME, HB_ERR_ARGS_BASEPARAMS );
   return NULL;
}



HB_FUNC( NETIO_GETSOCK )
{
   PHB_CONSRV conn = s_consrvParam( 1 );
   if( conn )
   {
      HB_SOCKET socket = hb_sockexGetHandle( conn->sock );
      if( socket )
      {
          hb_socketItemPut( hb_stackReturnItem(), socket );
      }
   }
}

#pragma ENDDUMP
*/

//eof
