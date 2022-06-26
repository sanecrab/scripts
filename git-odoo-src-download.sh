#!/bin/bash

#forma clasica https://github.com/<user>/<repo>/archive/<brand>.tar.gz
#BASE_URL=http://github.com/odoo/odoo/archive
#GitHub API v3
#https://api.github.com/repos/<user>/<repo>/<format tarball | zipball>/<brand>
BASE_URL=https://api.github.com/repos/odoo/odoo/tarball

ERROR_ARGS=5

if [ $# -eq 0 ] #Comprobar que se han pasado parametros
then
	echo "Usage: `basename $0` <odoo_version>"
	exit $ERROR_ARGS
fi

ODOO_VERSION=$1
ODOO_DIR=$ODOO_VERSION/odoo-$ODOO_VERSION

mkdir -p $ODOO_DIR
curl -L $BASE_URL/$ODOO_VERSION | tar -xz --strip-components=1 -C $ODOO_DIR
