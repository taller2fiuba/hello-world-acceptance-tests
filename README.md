# Pruebas de aceptación

Este script permite correr automáticamente las pruebas de aceptación. El mismo puede 
descargar y levantar automáticamente los servicios requeridos o utilizar servicios 
según la URL indicada.

## Requerimientos:
- Docker
- Docker Compose

## Cómo correr las pruebas

### Para correr las pruebas levantando automáticamente todos los servicios:

```bash
$ ./run-acceptance-tests.sh
```

El script clonará los repositorios, levantará los servicios mediante `docker-compose`
y luego se correrá behave dentro de un contenedor de Docker. Al finalizar se limpiaran 
los archivos temporales dejando el sistema donde se corrió intacto.
El único rastro que puede quedar son imagenes oficiales de Docker descargadas.

### Para correrlo utilizando un Hello Node en una URL específica:

```bash
$ ./run-acceptance-tests.sh --node-url=http://localhost:27080
```

En este caso sólo se clonará y levantará el servicio de Flask. Las pruebas
se correrán en un contenedor de Docker utilizando la URL indicada.

### Para correrlo sin levantar ningún servicio extra:

```bash
$ ./run-acceptance-tests.sh --node-url=http://localhost:27080 \
                           --flask-url=http://localhost:5000
```

En este caso no se clonará ningún repositorio, las pruebas se correrán dentro 
de Docker realizando solicitudes a dichas URL.

### Para correrlo desde un repositorio ya clonado

```bash
$ ./run-acceptance-tests.sh --node-repo=./hello-world-node
```

En este caso no se clonará el repo de Node, se levantará la versión productiva desde
el repositorio ya clonado en `./hello-world-node`, y se clonará la versión productiva
de Flask. En este caso no se realizará limpieza de la ejecución. El contenedor se 
detendrá mediante `docker-compose stop`.


Todos los parámetros `--<flask|node>-*` tienen su versión tanto para Node como para 
Flask aunque no esté explícitamente mencionado en el ejemplo.
