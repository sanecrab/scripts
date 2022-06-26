#!/bin/bash

#forma clasica https://github.com/<user>/<repo>/archive/<brand>.tar.gz
#BASE_URL=http://github.com/odoo/odoo/archive
#GitHub API v3
#https://api.github.com/repos/<user>/<repo>/<format tarball | zipball>/<brand>
BASE_URL=https://api.github.com/repos/OCA
DOWNLOAD_FORMAT=tarball

OCA_ADDONS=(account-analytic account-financial-reporting account-financial-tools account-invoicing account-payment bank-payment bank-statement-import commission community-data-files connector connector-ecommerce contract crm currency hr l10n-spain maintenance manufacture manufacture-reporting mis-builder partner-contact product-attribute product-variant project purchase-workflow queue reporting-engine sale-workflow server-brand server-tools server-ux social stock-logistics-reporting stock-logistics-warehouse stock-logistics-workflow timesheet web website)

ERROR_ARGS=5

if [ $# -eq 0 ] #Comprobar que se han pasado parametros
then
        echo "Usage: `basename $0` <odoo_version>"
        exit $ERROR_ARGS
fi

ODOO_VERSION=$1

OCA_ADDONS_DIR=$ODOO_VERSION/addons-lib/oca
mkdir -p $OCA_ADDONS_DIR

for((i=0;i<${#OCA_ADDONS[*]};i++))
do
	echo Descargando ${OCA_ADDONS[$i]}...
	TEMP_DIR=$OCA_ADDONS_DIR/${OCA_ADDONS[$i]}-$ODOO_VERSION
	mkdir -p $TEMP_DIR
	curl -L $BASE_URL/${OCA_ADDONS[$i]}/$DOWNLOAD_FORMAT/$ODOO_VERSION | tar -xz --strip-components=1 -C $TEMP_DIR
done

mkdir -p $ODOO_VERSION/addons

PARENT_DIR=$(pwd -P)
ln -sf $PARENT_DIR/$OCA_ADDONS_DIR/*/* $ODOO_VERSION/addons
