# hb_api_service
Un API muy básico usando servicio web y netIO de Harbour. Funcional en Windows y GNU/Linux

# Requisitos
Para ejecutar la primera vez, es necesario crear los certificados.

openssl genrsa -out privatekey.pem 2048
openssl req -new -subj "/C=LT/CN=mycompany.org/O=My Company" -key privatekey.pem -out certrequest.csr
openssl x509 -req -days 730 -in certrequest.csr -signkey privatekey.pem -out certificate.pem
openssl x509 -in certificate.pem -text -noout

# Binarios
Se incluye binarios para windows (32 bits) y gnu/linux ubuntu (64 bits)

# Inicio y pruebas
Luego de compilar, desde el mismo directorio del proyecto se debe invocar el binario, ejemplo:
c:\hb_api_service> hbmk2 hbnetio_tpy.hbp
c:\hb_api_service> bin\tpy_server.exe

Una vez iniciado el servicio, puede verificar el funcionamiento http visualizando desde el navegador colocando la dirección del servidor y el puerto 8001. Ejemplo:
https://localhost:8001

Esto despliega un mensaje de saludo e indica que el mensaje es parte de un metodo en la clase TACC "tpuy/tacc.prg".

Puede indentificarse con el servidor mediante: https://localhost:8001/html, aparece un formulario para indicar usuario y clave. (puede identificarse mediante el usuario: test clave: 12345678)

Una vez se identifica correctamente el usuario, aparece una pequeña información en pantalla con los datos del usuario y una cadena de idetificación para esta sesion (SESSION_ID).

La sesion corresponde a una clase en tpuy/tsession.prg, entonces para invocar el metodo 'help()' de la clase puede hacerlo mediante:
https://localhost:8001/SESSION_ID?help
 
Queda de su parte ahora extender estas clases para su uso particular.

Ejemplo de servicio con api para prestashop: https://www.youtube.com/watch?v=IW2GOfaMuR8


Tambien puede hacer pruebas desde su programa harbour haciendo uso de curl para comunicarse con el servidor mediante http o con hbnetio. En ambos casos el acceso es hacia las clases en el servidor.

Puede ver un ejemplo de conexión con hbnetio, en el directorio test.  



