#!/bin/sh
#
# Script installing all dependencies for neofetch and hosts based adblocker
# REQUIRE more than 16Mib flash and 64Mib RAM. Otherwise expect random behaviors...
#

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
			logger "installer[$$] : reinstalling wget with ssl support..."
			opkg update > /dev/null 2>&1
			opkg install libustream-openssl > /dev/null 2>&1 #ca-bundle ca-certificates
			opkg install wget --force-reinstall > /dev/null 2>&1
		fi
	else
		echo "Installing wget ssl, bash"
		logger "installer[$$] : installing wget with ssl support..."
		opkg update > /dev/null 2>&1
		opkg install libustream-openssl ca-bundle ca-certificates > /dev/null 2>&1
		opkg install wget > /dev/null 2>&1
        opkg install bash > /dev/null 2>&1
	fi
}

update_ps1() 
{
    echo "Updating PS1"
    logger "installer[$$] : updating PS1"
    PS1LINE="export PS1="
    NEWPS1="##export PS1='${debian_chroot:+($debian_chroot)}\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '"
    sed -e 's/\(^.*${PS1LINE}.*$\)/${NEWPS1}\1/' /etc/profile
}

install_neofetch() 
{
    echo "Downloading neofetch"
    logger "installer[$$] : Downloading neofetch"
    wget -O /bin/neofetch "https://raw.githubusercontent.com/dylanaraps/neofetch/master/neofetch" 
    chmod +x /bin/neofetch
    
    echo "setting up neofetch..."
    sed -i 's/\[ -f \/etc\/banner \] && cat \/etc\/banner/#&/' /etc/profile
    sed -i 's/\[ -n "$FAILSAFE" \] && cat \/etc\/banner.failsafe/& || \/bin\/neofetch/' /etc/profile
}

install_add_blocker() 
{
    echo "Downloading adblocker"
    logger "installer[$$] : Downloading adblocker"
    wget -O /bin/ad_block ""
    chmod +x /bin/ad_block
    
    /bin/ad_block -f
}



case "$1" in 
	"-i")
        check_for_dependencies
        update_ps1
        install_neofetch
        install_add_blocker
		;;
	"-h")
        echo "-i for installing : RUN ONLY ONCE"
		;;
	*)
        echo "Use -h for general usage"
		;;
esac