#!/bin/sh
#
# created by RedEye : ad_block.sh script v2 with wget instead of cURL
#
######                ####### #     #        
#     # ###### #####  #        #   #  ###### 
#     # #      #    # #         # #   #      
######  #####  #    # #####      #    #####  
#   #   #      #    # #          #    #      
#    #  #      #    # #          #    #      
#     # ###### #####  #######    #    ######
#
# adaway hosts sources :
# https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext
# https://adaway.org/hosts.txt --> ERROR SSLV2 and PolarSSL !!! SOLVE WITH check_for_dependencies
# http://winhelp2002.mvps.org/hosts.txt
# https://hosts-file.net/ad_servers.txt
# http://someonewhocares.org/hosts/zero/hosts 
#
# Once merged file -> 2 mb

FILE="/tmp/hosts_ads.txt"
ENDPOINT="0.0.0.0"

check_for_dependencies()
{
	OPKG=`opkg list-installed wget | grep wget`
	if [ "${OPKG}" != ""  ]
	then
		SSL=`wget --version | grep +ssl`
		if [ "${SSL}" != "" ]
		then
			echo "wget ssl is founded"
			logger "ad_block[$$] : wget ssl is founded skipping"
		else
			echo "Reinstalling wget with ssl support..."
			logger "ad_block[$$] : reinstalling wget with ssl support..."
			opkg update > /dev/null 2>&1
			opkg install libustream-openssl > /dev/null 2>&1 #ca-bundle ca-certificates
			opkg install wget --force-reinstall > /dev/null 2>&1
		fi
	else
		echo "Installing wget ssl..."
		logger "ad_block[$$] : installing wget with ssl support..."
		opkg update > /dev/null 2>&1
		opkg install libustream-openssl > /dev/null 2>&1 #ca-bundle ca-certificates
		opkg install wget > /dev/null 2>&1
	fi
}


valid_connection()
{
	ping -q -w 1 -c 1 8.8.8.8 > /dev/null && return 0 || return 1
}


install_file()
{
	CONNECTION=$(valid_connection)
	if [ "${CONNECTION}" = "1"  ]
	then
		echo "No connection found"
		logger "ad_block[$$] : no connection found"
		return 1
	fi
	
	if [ -e "$FILE" ]
	then
		echo "File is existing : removing..."
		logger "ad_block[$$] : removing old host file at $FILE"
		rm $FILE
	fi
	
	logger "ad_block[$$] : Getting host files..."
	echo "Getting host files..."
	{ wget -qO- --no-check-certificate http://winhelp2002.mvps.org/hosts.txt | grep "${ENDPOINT}" | sed 's/[[:space:]]*#.*$//g;' | grep -v localhost | tr ' ' '\t' | tr -s '\t' | tr -d '\015' \
	  && wget -qO- --no-check-certificate https://hosts-file.net/ad_servers.txt | grep 127.0.0.1 | sed "s/127.0.0.1/${ENDPOINT}/g;" | sed 's/[[:space:]]*#.*$//g;' | grep -v localhost | tr ' ' '\t' | tr -s '\t' | tr -d '\015' \
	  && wget -qO- --no-check-certificate https://adaway.org/hosts.txt | grep 127.0.0.1 | sed "s/127.0.0.1/${ENDPOINT}/g;" | sed 's/[[:space:]]*#.*$//g;' | grep -v localhost | tr ' ' '\t' | tr -s '\t' | tr -d '\015' \
	  && wget -qO- --no-check-certificate "https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext" | grep -v "<" | grep 127.0.0.1 | sed "s/127.0.0.1/${ENDPOINT}/g;" | sed 's/[[:space:]]*#.*$//g;' | grep -v localhost | tr ' ' '\t' | tr -s '\t' | tr -d '\015';} | sort -u >${FILE}
	  
	echo "Succefully installed"
	logger "ad_block[$$] : succefully installed"
}


case "$1" in 
	"-f")
		check_for_dependencies
		install_file
		uci add_list dhcp.@dnsmasq[0].addnhosts=$FILE > /dev/null 2>&1 && uci commit
		;;
	"-s")
		uci del_list dhcp.@dnsmasq[0].addnhosts=$FILE > /dev/null 2>&1 && uci commit
		;;
	"-h")
		echo "Usage :\n-f for first install\n-s to delete\nno arguments for update"
		;;
	*)
		install_file
		;;
esac

killall dnsmasq
/etc/init.d/dnsmasq start
