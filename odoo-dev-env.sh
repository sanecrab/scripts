#!/bin/bash

ERROR_EXIT=9
ERROR_ARGS=5
ERROR_COMMAND=127

# Reset text color
COLOR_OFF='\033[0m'

#Colors
RED='\033[0;31m'
YELLOW='\033[0;33m'

CLIENT_NAME=$1
ODOO_VERSION=$2

DB_NAME=$CLIENT_NAME-v$ODOO_VERSION-dev

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

function odoo_system_requiremments()
{
    #sudo apt install ....
    # clean python2
    #sudo apt purge -y python2.7 python2.7-minimal
    sudo apt autoremove -y --purge

    # python2 + python3 + venv
    sudo apt-get install -y python python-dev python-pip python-setuptools
    sudo apt-get install -y python3 python3-dev python3-pip python3-setuptools python3-renderpm
    sudo pip3 install setuptools wheel

    # se valida que no exista el repositorio
    if ! grep -rwnq "deadsnakes/ppa" /etc/apt/
    then
        sudo add-apt-repository ppa:deadsnakes/ppa
        sudo apt-get update
    fi
    #python3.6
    sudo apt-get install -y python3.6 python3.6-dev python3.6-gdb python3.6-distutils
    sudo apt-get install -y python3-virtualenv
    
    # update-alternatives python TODO: validar
    sudo update-alternatives --install /usr/bin/python python /usr/bin/python2.7 0
    sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.6 0
    sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.8 0

    # system base
    sudo apt install -y ca-certificates curl dirmngr mc nano bash-completion less
    sudo apt install -y bzip2 zip unzip gettext-base openssh-client telnet xz-utils zlibc
    sudo apt install -y ssh build-essential git

    # dependency libs
    sudo apt install -y fontconfig libfreetype6 libjpeg-turbo8 libx11-6 libxext6 libxml2 libxrender1 libxslt1.1 zlib1g
    sudo apt install -y xfonts-75dpi xfonts-100dpi xfonts-base xfonts-scalable
    sudo apt install -y nodejs node-clean-css node-less

    # c2c / tn extras
    sudo apt install -y antiword ghostscript graphviz poppler-utils
    sudo apt install -y liblcms2-2 libldap-2.4-2 libsasl2-2 libtiff5

    # development libraries
    sudo apt install -y libevent-dev libjpeg-dev libldap2-dev libsasl2-dev libssl-dev libxml2-dev libxslt1-dev zlib1g-dev
    sudo apt install -y libxml2-dev libxmlsec1-dev libxmlsec1-openssl
    # virtualenv + pip
    sudo apt install -y virtualenv
    
    # wkthml2pdf 0.12.5
    wkhtmltopdf --version | grep '(with patched qt)'
    if [ $? -ne 0 ]
    then
		echo 'Instalando wkthml2pdf 0.12.5...'
		WKHTMLTOPDF_VERSION=0.12.5
        WKHTMLTOPDF_CHECKSUM='db48fa1a043309c4bfe8c8e0e38dc06c183f821599dd88d4e3cea47c5a5d4cd3'
        curl -SLo wkhtmltox.deb https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/${WKHTMLTOPDF_VERSION}/wkhtmltox_${WKHTMLTOPDF_VERSION}-1.bionic_amd64.deb && echo "${WKHTMLTOPDF_CHECKSUM} wkhtmltox.deb" | sha256sum -c - && sudo apt-get install -yqq --no-install-recommends ./wkhtmltox.deb && rm wkhtmltox.deb && wkhtmltopdf --version       
    fi

    # ------------------------------------------------------------------------------
    # clean packages
    # ------------------------------------------------------------------------------
    sudo apt autoremove --purge -y
    sudo apt clean
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
addons_path = $3/my-addons, $3/custom-addons, $3/odoo-server/addons
data_dir = $3/data

# database
db_host = False
db_port = False
db_user = $USER
db_password = False
dbfilter = ^$DB_NAME$

# logfiles
log_level = info
log_handler = *:ERROR,werkzeug:CRITICAL

# xmlrpc
xmlrpc = True
xmlrpc_interface = 127.0.0.1
xmlrpc_port = 8080
longpolling_port = 8081

# workers configuration
#workers = 4
#max_cron_threads = 1
#db_maxconn = 10
#limit_memory_hard = 2684354560
#limit_memory_soft = 2147483648
#limit_request = 8192
#limit_time_cpu = 900
#limit_time_real = 1800
limit_time_cpu = 99999
limit_time_real = 99999

# Connector
#server_wide_modules = web,queue_job
server_wide_modules = web

#[queue_job]
#channels = root:2
"
    echo "$odoo_conf" > $3/$odoo_conf_file
}

function odoo_bin_init_creation()
{
    odoo_bin_file=odoo-bin
    odoo_bin="
#!/bin/bash
params=\" -c ./odoo.conf --log-level info \"
sudo -u $USER ./venv/bin/python ./odoo-server/odoo-bin \$@ \$params
"
    echo "$odoo_bin" > $odoo_bin_file
    sudo chmod +x $odoo_bin_file
}

function odoo_shell_init_creation()
{
    odoo_shell_file=odoo-shell
    odoo_shell="
#!/bin/bash
./odoo-bin shell --no-http \$@
"
    echo "$odoo_shell" > $odoo_shell_file
    sudo chmod +x $odoo_shell_file
}

#Descargar el código fuente de Odoo
#download_odoo <directorio de Odoo>
function download_odoo()
{
    #forma clasica https://github.com/<user>/<repo>/archive/<brand>.tar.gz
    #BASE_URL=http://github.com/odoo/odoo/archive
    #GitHub API v3
    #https://api.github.com/repos/<user>/<repo>/<format tarball | zipball>/<brand>
    BASE_URL=https://api.github.com/repos/odoo/odoo/tarball
    
    #Comprobar parms
    if [ -z $1 ]
    then
        echo -e "${RED}ERROR: Error al descargar las fuentes de Odoo versión \"$ODOO_VERSION\" ${COLOR_OFF}"
        return $ERROR_ARGS
    fi
    
    ODOO_DIR=$1
    mkdir -p $ODOO_DIR
    curl -L $BASE_URL/$ODOO_VERSION | tar -xz --strip-components=1 -C $ODOO_DIR
}

#Descargar los módulos de la OCA
function download_oca_addons()
{
    #forma clasica https://github.com/<user>/<repo>/archive/<brand>.tar.gz
    #BASE_URL=http://github.com/odoo/odoo/archive
    #GitHub API v3
    #https://api.github.com/repos/<user>/<repo>/<format tarball | zipball>/<brand>
    BASE_URL=https://api.github.com/repos/OCA
    DOWNLOAD_FORMAT=tarball

    OCA_ADDONS=(account-analytic account-closing account-financial-reporting account-financial-tools account-invoicing account-payment account-reconcile bank-payment bank-statement-import commission community-data-files contract crm currency donation hr l10n-spain maintenance manufacture manufacture-reporting mis-builder partner-contact product-attribute product-variant project purchase-workflow queue reporting-engine sale-workflow server-brand server-tools server-ux social stock-logistics-reporting stock-logistics-warehouse stock-logistics-workflow timesheet web website)

    #Comprobar parms
    if [ -z $ODOO_VERSION ]
    then
        echo -e "${RED}ERROR: Error al descargar los addons de la OCA versión \"$ODOO_VERSION\" ${COLOR_OFF}"
        return $ERROR_ARGS
    fi
    
    OCA_ADDONS_DIR=./addons-lib/oca
    mkdir -p $OCA_ADDONS_DIR

    for((i=0;i<${#OCA_ADDONS[*]};i++))
    do
        echo Descargando ${OCA_ADDONS[$i]}...
        TEMP_DIR=$OCA_ADDONS_DIR/${OCA_ADDONS[$i]}
        mkdir -p $TEMP_DIR
        curl -L $BASE_URL/${OCA_ADDONS[$i]}/$DOWNLOAD_FORMAT/$ODOO_VERSION | tar -xz --strip-components=1 -C $TEMP_DIR
    done
}

#Se descargan los módulos de RGB
function download_rgb_addons()
{
    BASE_URL=https://api.github.com/repos/rgbconsulting/odoo-addons
    DOWNLOAD_FORMAT=tarball

    #Comprobar parms
    if [ -z $ODOO_VERSION ]
    then
        echo -e "${RED}ERROR: Error al descargar los addons de RGB versión \"$ODOO_VERSION\" ${COLOR_OFF}"
        return $ERROR_ARGS
    fi
    
    RGB_ADDONS_DIR=./addons-lib/rgbconsulting
    mkdir -p $RGB_ADDONS_DIR
    
    curl -L $BASE_URL/$DOWNLOAD_FORMAT/$ODOO_VERSION | tar -xz --strip-components=1 -C $RGB_ADDONS_DIR
}

if [ -z $CLIENT_NAME ] || [ -z $ODOO_VERSION ] #Comprobar parms
then
        show_usage
        exit $ERROR_ARGS
fi

#Instalar dependencias del SO
echo ""
echo "Instalando dependencias del sistema para Odoo..."
odoo_system_requiremments

#Crear estructura de carpetas y ficheros base
echo ""
echo "Creando estructura de carpetas en \"`pwd`/$DEST_DIR\"..."
DEST_DIR=$CLIENT_NAME
mkdir $DEST_DIR
cd $DEST_DIR
mkdir -p custom-addons my-addons thirdparty-addons data/filestore

#Descarga de módulos de la oca (addons-lib)
echo ""
echo "Descargando módulos de la OCA para la versión \"$ODOO_VERSION\"..."
#download_oca_addons
#Descarga de módulos de RGB (addons-lib)
echo ""
echo "Descargando módulos de RGB para la versión \"$ODOO_VERSION\"..."
#download_rgb_addons 

#Creación de ficheros de configuración
echo ""
echo "Creando fichero de configuración \"$(pwd)/odoo.conf\"..."
odoo_conf_creation $CLIENT_NAME $ODOO_VERSION $(pwd)
echo "Creando fichero de configuración \"$(pwd)/odoo-bin\"..."
odoo_bin_init_creation
echo "Creando fichero de configuración \"$(pwd)/odoo-shell\"..."
odoo_shell_init_creation

# Validar existencia de los ficheros del servidor de Odoo(community o enterprise)
# Si no existe, se descarga
echo ""
COMMUNITY_BASE_DIR=/opt/odoo/community
if [ ! -e $COMMUNITY_BASE_DIR/odoo-$ODOO_VERSION ]
then
    echo -e "${YELLOW}WARNING: No se ha encontrado el servidor odoo \"$ODOO_VERSION\" base ${COLOR_OFF}"
    # Community
    mkdir -p $COMMUNITY_BASE_DIR
    echo "Descargando las fuentes del servidor de Odoo \"$ODOO_VERSION\"..."
    download_odoo $COMMUNITY_BASE_DIR/odoo-$ODOO_VERSION
    # Enterprise
fi

#Crear acceso directo a Odoo Base
echo "Creando enlace al servidor de Odoo \"$ODOO_VERSION\"..."
ln -sf $COMMUNITY_BASE_DIR/odoo-$ODOO_VERSION odoo-server
if [ $? -eq 0 ]
then
    echo "$(ls -l $(pwd)/odoo-server | awk {'print $9 " " $10 " " $11'})"
fi

#Creación del entorno virtual e instalación de dependencias de python para Odoo
echo ""
mkdir venv
if (( $(echo "$ODOO_VERSION > 10.0" | bc -l) ))
then
    if (( $(echo "$ODOO_VERSION > 13.0" | bc -l) ))
    then
        python3.8 --version
        if [ $? -eq 0 ]
        then
            echo "Instalando virtualenv $(python3.8 --version)..."
            virtualenv --python=python3.8 venv
        else
            echo -e "${RED}ERROR: Se debe instalar python3.8 ${COLOR_OFF}"
        fi
    else
        python3.6 --version
        if [ $? -eq 0 ]
        then
            echo "Instalando virtualenv $(python3.6 --version)..."
            virtualenv --python=python3.6 venv
        else
            python3 --version
            if [ $? -eq 0 ]
            then
                echo "Instalando virtualenv $(python3 --version)..."
                virtualenv --python=python3 venv
            else
                echo -e "${RED}ERROR: Se debe instalar python3 ${COLOR_OFF}"
            fi
        fi
else
    python2 --version
    if [ $? -eq 0 ]
    then
        echo "Instalando virtualenv $(python2 --version)..."
        virtualenv --python=python2 venv
    else
        echo -e "${RED}ERROR: Se debe instalar python2 ${COLOR_OFF}"
    fi
fi

echo ""
echo "Instalando las dependencias de python del servidor de Odoo \"$ODOO_VERSION\"..."
echo "$(ls -l $(pwd)/odoo-server | awk {'print $9 " " $10 " " $11'})"
venv/bin/python -m pip install -r odoo-server/requirements.txt

#Crear usuario de BD
echo "Creando el usuario de base de datos \"$USER\""
sudo -u postgres createuser -dS $USER

#Crear la base de datos <cliente>-<version odoo>-dev
#Ej: 
#   createdb client1-v12.0-dev
echo ""
echo "Creando la base de datos \"$DB_NAME\""
createdb "$DB_NAME"

echo ""
echo "Acciones post-instalación:"
echo -e "${YELLOW}"
echo "1- Instalar los requisitos de python a partir del \"venv\" del cliente \"$CLIENT_NAME\""
echo "En el vps del cliente ejecutar:"
echo "    /opt/odoo/sites/0001/venv/bin/python -m pip freeze"
echo "En Local ejecutar:"
echo "    $(pwd)/venv/bin/python -m pip -install -r client-pip-freeze.txt"
echo "2- Restaurar la copia de base de datos en la BD creada"
echo "Ejecutar:"
echo "    sudo -u $USER psql -d $DB_NAME < BACKUP.sql > /dev/null sustituyendo \"BACKUP.sql\" por el nombre del fichero de copia de BD"
echo "3- Copiar los módulos de la OCA y RGB necesarios para el cliente \"$CLIENT_NAME\""
echo "4- Clonar el repositorio de Gitea para el cliente \"$CLIENT_NAME\" en el directorio \"my-addons\""
echo -e "${COLOR_OFF}"

