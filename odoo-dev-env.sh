#!/bin/bash

ERROR_ARGS=5

CLIENT_NAME=$1
ODOO_VERSION=$2

function show_usage()
{
    usage="
    Usage:
        $(basename $0) <nombre de cliente> <odoo_version>
    Ej:
        $(basename $0) cliente-temp 12.0
    "
    echo "$usage"
}

# crea el fichero de configuración para la instancia
# $1: Nombre del cliente
# $2: Version
# $3: Directorio base
function odoo_conf_creation()
{
    odoo_conf_file=odoo.conf
    odoo_conf="
[options]
admin_passwd = S1sDb4@dev

# addons & data
addons_path = $3/my-addons,$3/addons,$3/server/addons
data_dir = $3/data

# database
list_db = False
dbfilter = ^$1-$2-dev$
db_host = False
db_port = False
db_name = False
db_user = $USER
db_password = False

# logfiles
log_level = info
log_handler = *:ERROR,werkzeug:CRITICAL

# xmlrpc
xmlrpc = True
xmlrpc_interface = 127.0.0.1
xmlrpc_port = 8080
longpolling_port = 8081

# workers configuration
workers = 2
max_cron_threads = 1
db_maxconn = 10
limit_memory_hard = 2684354560
limit_memory_soft = 2147483648
limit_request = 8192
limit_time_cpu = 900
limit_time_real = 1800

# Connector
server_wide_modules = web,queue_job

[queue_job]
channels = root:2
"
    echo "$odoo_conf" > $3/$odoo_conf_file
}

function odoo_bin_creation()
{
    odoo_bin_file=odoo-bin
    odoo_bin="
#!/bin/bash
params=\" -c odoo.conf --log-level info \"
sudo -u $USER ./venv/bin/python ./server/odoo-bin $@ $params
"
    echo "$odoo_bin" > $odoo_bin_file
}

if [ -z $CLIENT_NAME ] || [ -z $ODOO_VERSION ] #Comprobar parms
then
        show_usage
        exit $ERROR_ARGS
fi

#1- Crear estructura de carpetas y ficheros base
DEST_DIR=$CLIENT_NAME-dev
echo "Creando estructura de carpetas en \"`pwd`/$DEST_DIR\"..."
mkdir $DEST_DIR
cd $DEST_DIR
mkdir -p addons my-addons data/filestore

#Creación de ficheros de configuración
odoo_conf_creation $CLIENT_NAME $ODOO_VERSION $(pwd)
odoo_bin_creation

#Creación del entorno virtual e instalación de dependencias de python para Odoo
mkdir venv
if (( $(echo "$ODOO_VERSION > 10.0" | bc -l) ))
then
    echo "Instalando $(python3 --version)..."
    virtualenv --python=python3 venv
else
    echo "Instalando $(python2 --version)..."
    virtualenv --python=python2 venv
fi
venv/bin/python -m pip install -r server/requirements.txt

#2- Validar existencia de los ficheros del servidor de Odoo(community o enterprise)
COMMUNITY_BASE_DIR=/opt/odoo/src/$ODOO_VERSION/community
if [ ! -e /opt/odoo/src/12.0/community/odoo-12.0 ]
then
    # Community
    mkdir -p $COMMUNITY_BASE_DIR
    # Enterprise
fi


#2- Crear la base de datos <cliente>-<version odoo>-dev
#Ej: 
#   createdb guifinet-v12-dev
#3- 
#
#
#
#
#
#
#
#
#
#
#
#
#
