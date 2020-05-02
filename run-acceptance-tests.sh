#!/bin/bash

# Este script permite correr automáticamente las pruebas de aceptación.
# El mismo puede descargar y levantar automáticamente los servicios requeridos
# o utilizar servicios según la URL indicada.
#
# Para correr las pruebas levantando automáticamente todos los servicios:
# ./run-acceptance-tests.sh
# Se clonarán los repositorios, levantaran los servicios mediante docker-compose
# y luego se correrá behave dentro de un contenedor de Docker. Al finalizar se
# limpiaran los archivos temporales dejando el sistema donde se corrió intacto.
# El único rastro que puede quedar son imagenes oficiales de Docker descargadas.
#
# Para correrlo utilizando un Hello Node en una URL específica:
# ./run-acceptance-tests.sh --node-url=http://localhost:27080
# En este caso sólo se clonará y levantará el servicio de Flask. Las pruebas
# se correrán en un contenedor de Docker utilizando la URL indicada.
#
# Para correrlo sin levantar ningún servicio extra:
# ./run-acceptance-tests.sh --node-url=http://localhost:27080 \
#                           --flask-url=http://localhost:5000
# En este caso no se clonará ningún repositorio, las pruebas se correrán
# dentro de Docker realizando solicitudes a dichas URL.
#
# Para correrlo levantando la versión productiva desde un repositorio ya clonado:
# ./run-acceptance-tests.sh --node-repo=./hello-world-node
# En este caso no se realizará limpieza de la ejecución. El contenedor se 
# detendrá mediante `docker-compose stop`.
#
# Todos los parámetros --<flask|node>-* tienen sus versiones tanto para node 
# como para flask aunque no esté mencionado en el ejemplo.

REPO_HELLO_NODE="https://github.com/taller2fiuba/hello-world-node"
REPO_HELLO_FLASK="https://github.com/taller2fiuba/hello-world-flask"

function print_usage() {
    echo "Corre las pruebas de aceptación."
    echo "Uso: $0 [--flask-url=<FLASK URL>] [--node-url=<NODE URL>]"
    echo "Si se le pasa --flask-url y/o --node-url se utilizarán esas URLs para"
    echo "contactar al servidor de Flask y Node, respectivamente."
    echo "Si no se pasa alguno de esos parámetros el script levantará una imagen"
    echo "productiva del servidor correspondiente mediante docker-compose".
}

# Procesar argumentos
for arg in "$@"
do
case $arg in
    --flask-url=*)
        export FLASK_URL="${arg#*=}"
    shift
    ;;
    --node-url=*)
        export NODE_URL="${arg#*=}"
    shift
    ;;
    --node-repo=*)
        export NODE_REPO_DIR=$(readlink -f "${arg#*=}")
    shift
    ;;
    --flask-repo=*)
        export FLASK_REPO_DIR=$(readlink -f "${arg#*=}")
    shift
    ;;
    *)
         print_usage;
         exit 1;
    ;;
esac
done

function get_random_free_port() {
    while :
    do
        PORT="`shuf -i 49152-65535 -n 1`"
        ss -lpn | grep -q ":$PORT " || break
    done
    echo $PORT
}    

function wait_server() {
    TIMEOUT=60
    until curl -s -o /dev/null --connect-timeout 1 $1;
    do
        echo "Esperando $TIMEOUT segs para $1."
        sleep 5
        TIMEOUT=$((TIMEOUT-5))
        if ((TIMEOUT < 0)); then
            echo 'Se acabó el tiempo de espera'
            exit 1
        fi
    done;
}

function cleanup() {
    # Limpieza
    if [[ -d $TMPDIR/hello-world-node ]]; then
        cd $TMPDIR/hello-world-node
        docker-compose down -v --rmi local
    else
        if [[ -d $NODE_REPO_DIR ]]; then
            cd $NODE_REPO_DIR
            docker-compose stop
        fi
    fi
    if [[ -d $TMPDIR/hello-world-flask ]]; then
        cd $TMPDIR/hello-world-flask
        docker-compose down -v --rmi local
    else 
        if [[ -d $FLASK_REPO_DIR ]]; then
            cd $FLASK_REPO_DIR
            docker-compose stop
        fi
    fi
    cd $TMPDIR/..
    rm -rf $TMPDIR
}

function setup_flask() {
    if [[ ! $FLASK_REPO_DIR ]]; then
        echo 'Obteniendo versión productiva de Hello Flask'
        cd $TMPDIR
        git clone $REPO_HELLO_FLASK
        export FLASK_REPO_DIR=$TMPDIR/hello-world-flask
    fi
    cd $FLASK_REPO_DIR
    export HELLO_FLASK_PORT=$(get_random_free_port)
    export FLASK_URL="http://localhost:$HELLO_FLASK_PORT"
    echo "Configurando versión productiva de Hello Flask en $FLASK_URL"
    docker-compose up -d --build
    wait_server $FLASK_URL
}

function setup_node() {
    if [[ ! $NODE_REPO_DIR ]]; then
        echo 'Obteniendo versión productiva de Hello Node'
        cd $TMPDIR
        git clone $REPO_HELLO_NODE
        export NODE_REPO_DIR=$TMPDIR/hello-world-node
    fi
    cd $NODE_REPO_DIR
    export HELLO_NODE_PORT=$(get_random_free_port)
    export NODE_URL="http://localhost:$HELLO_NODE_PORT"
    echo "Configurando versión productiva de Hello Node en $NODE_URL"
    docker-compose up -d --build
    wait_server $NODE_URL
}

trap cleanup EXIT
set -e

ACCEPTANCE_TESTS_DIR=$(pwd)

# Crear una carpeta temporal
TMPDIR=$(mktemp -d -t ci-XXXXXXXXXX)
cd $TMPDIR

if [[ ! $NODE_URL ]]; then
    setup_node
fi

if [[ ! $FLASK_URL ]]; then
    setup_flask
fi

echo 'Corriendo behave...'
docker run -it --network="host" \
    -e FLASK_URL=$FLASK_URL \
    -e NODE_URL=$NODE_URL \
    -v $ACCEPTANCE_TESTS_DIR:/tests \
    -w /tests \
    python:3.8 \
    sh -c 'pip install -r requirements.txt && behave'

# La limpieza se hace automáticamente antes de que termine el proceso de bash
