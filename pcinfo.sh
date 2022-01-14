#!/bin/bash

clear

IFS=$'\r\n'
GLOBIGNORE='*'

#Eliminar espacios (o caracteres en $2) de la cadena de entrada $1
_trim_chars()
{
	_TRIMED=$1
	for_trim=${_TRIMED##*[!${2:- }]}	#caracteres al final
	_TRIMED=${_TRIMED%"$for_trim"}
	for_trim=${_TRIMED%%[!${2:- }]*}	#caracteres al inicio
	_TRIMED=${_TRIMED#"$for_trim"}
	echo $_TRIMED
}

#Convertir unidades $1 de tipo $2 a tipo $3. Ej: 2048 kb gb
_unit_conv()
{
_CONV_RESULT=$1
if [ ${2,,} = ${3,,} ]
then
	echo "$_CONV_RESULT"
	exit 0
fi

case ${2,,} in
	'b')
		case ${3,,} in
			'kb') _divider=1000.0 ;;
			'mb') _divider=$((1000*1000)).0 ;;
			'gb') _divider=$((1000*1000*1000)).0 ;;
		esac
	;;
	'kb') 
		case ${3,,} in
			'b') _divider=0.001 ;;
			'mb') _divider=$((1000)).0 ;;
			'gb') _divider=$((1000*1000)).0 ;;
		esac
	;;
	'mb') 
		case ${3,,} in
			'b') _divider=0.000001 ;;
			'kb') _divider=$(0.001) ;;
			'gb') _divider=$((1000)).0 ;;
		esac
	;;
esac
_CONV_RESULT=$(bc << EOF
scale = 2
$_CONV_RESULT / $_divider
EOF
)
echo "$_CONV_RESULT"
}

_begin_with_num()
{
	ch=$(_trim_chars $1)
        ch=${ch:0:1}
        num=$((ch + 0))
        case $num in
        *[!0−9]*|"") return 0;;
                *) return -1;;
        esac
}

#Sección Sistema Inicio
echo "-----------------"
echo "---- Sistema ----"
echo "-----------------"

echo "Sistema Operativo:" $(cat /etc/os-release | grep "PRETTY_NAME" | cut -d '=' -f 2 | cut -d '"' -f 2)
echo "Versión Kernel   :" $(uname -r)
echo "Plataforma       :" $(uname -p)

#Sección Sistema Fin

#Sección Base Board Inicio
echo ""
echo "--------------------"
echo "---- Placa Base ----"
echo "--------------------"
echo "Fabricante:" $(/usr/sbin/dmidecode --type 2 | grep "Manufacturer:" | cut -d ':' -f 2)
echo "Modelo    :" $(/usr/sbin/dmidecode --type 2 | grep "Product Name:" | cut -d ':' -f 2)
#Sección Base Board Fin

#Sección CPU Inicio
processor_ids=($(cat /proc/cpuinfo | grep "processor" | cut -d ':' -f 2))
model_names=($(cat /proc/cpuinfo | grep "model name" | cut -d ':' -f 2))
cpu_families=($(cat /proc/cpuinfo | grep "cpu family" | cut -d ':' -f 2))
cpu_caches=($(cat /proc/cpuinfo | grep "cache size" | cut -d ':' -f 2))

echo ""
echo "-------------------------"
echo "---- CPU (${#processor_ids[@]} núcleos) ----"
echo "-------------------------"
 
echo "ID | Modelo | Familia | Cache"
echo "-----------------------------"
for pos in $(seq 0 $((${#processor_ids[@]} - 1))); do
	pnum=$(_trim_chars ${processor_ids[$pos]})
	pmodel=$(_trim_chars ${model_names[$pos]})
	cfamily=$(_trim_chars ${cpu_families[$pos]})
	pcache=$(_trim_chars ${cpu_caches[$pos]})
	echo "$pnum | $pmodel | $cfamily | $pcache"
done
#Sección CPU Fin

#Sección RAM Inicio
ram_total=$(cat /proc/meminfo | grep "MemTotal" | cut -d ':' -f 2)
ram_total=$(_trim_chars $ram_total)
unit=$(echo $ram_total | cut -d ' ' -f 2)
ram_total=$(echo $ram_total | cut -d ' ' -f 1)

ram_total_gb=$(_unit_conv $ram_total $unit "gb")
ram_total_gb_int=$(echo $ram_total_gb | cut -d '.' -f 1)

echo ""
echo "----------------------"
echo "---- RAM ($ram_total_gb_int GB) ----"
echo "----------------------"
swap_total=$(cat /proc/meminfo | grep "SwapTotal" | cut -d ':' -f 2)
swap_total=$(_trim_chars $swap_total)
unit=$(echo $swap_total | cut -d ' ' -f 2)
swap_total=$(echo $swap_total | cut -d ' ' -f 1)

swap_total_gb=$(_unit_conv $swap_total $unit gb)
swap_total_gb_int=$(echo $swap_total_gb | cut -d '.' -f 1)
max_ram_capacity=$(/usr/sbin/dmidecode -t memory | grep "Maximum Capacity" | cut -d ':' -f 2)
max_ram_capacity=$(_trim_chars $max_ram_capacity)
unit=$(echo $max_ram_capacity | cut -d ' ' -f 2)
max_ram_capacity=$(echo $max_ram_capacity | cut -d ' ' -f 1)
max_ram_capacity_gb=$(_unit_conv $max_ram_capacity $unit gb)

echo "Capacidad máxima:" $max_ram_capacity_gb GB
echo "RAM instalada   :" $ram_total_gb GB
echo "Memoria SWAP    :" $swap_total_gb GB
echo ""
ram_types=($(/usr/sbin/dmidecode --type 17 | grep "Type:" | cut -d ':' -f 2))
ram_locators=($(/usr/sbin/dmidecode --type 17  | grep -E "[^a-zA-Z0-9 ]Locator:" | cut -d ':' -f 2))
ram_manufactures=($(/usr/sbin/dmidecode --type 17 | grep "Manufacturer:" | cut -d ':' -f 2))
ram_sizes=($(/usr/sbin/dmidecode --type 17 | grep "Size:" | cut -d ':' -f 2))
ram_serials=($(/usr/sbin/dmidecode --type 17 | grep "Serial Number:" | cut -d ':' -f 2))

#Number Of Devices: 4, se debe ver si estos son los utilizados o los disponibles
echo "Bancos de memoria en uso ():"
echo "----------------------------"
echo "Tipo | Ubicación | Fabricante | Capacidad | Número de serie"
echo "-----------------------------------------------------------"
for pos in $(seq 0 $((${#ram_types[@]} - 1))); do
	rtype=$(_trim_chars ${ram_types[$pos]})
	rlocator=$(_trim_chars ${ram_locators[$pos]})
	rmanuf=$(_trim_chars ${ram_manufactures[$pos]})
	rsize=$(_trim_chars ${ram_sizes[$pos]})
	if ! _begin_with_num $rsize
	then
		continue
	fi
	rsize_num=$(echo $rsize | cut -d ' ' -f 1)
        unit=$(echo $rsize | cut -d ' ' -f 2)
        unit=${unit,,}
        rsize_gb=$(_unit_conv $rsize_num $unit "gb")
	rserial=$(_trim_chars ${ram_serials[$pos]})
	echo "$rtype | $rlocator | $rmanuf | $rsize_gb GB | $rserial"
done

#Ej:
#DIMM 1A 16384 MB 2400 MHz
#DIMM 1B 16384 MB 2400 MHz
#Sección RAM Fin


#Sección HDD Inicio
echo ""
echo "-------------"
echo "---- HDD ----"
echo "-------------"
#Ej:
#/dev/sda(999.7 GB)
#SATA1DATA  931G

#/dev/sdb(239.5 GB)
#SSDDB         223G

#Sección HDD Fin

