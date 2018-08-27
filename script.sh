#!/bin/bash


read -p  "debian or centos?" OS

read -p  "Count of ip?" IPCOUNT


function prepList()
{
    printf "                       \
  " > .iplist

    readarray array < .iplist

    }


function ipPrechek()
{

	echo "Select subnet:"
	for index in ${!array[*]}
	do
    	printf "%4d: %s\n" $index ${array[$index]}
	done
	read select
	fping -q -g -u ${array[$select]} | head -n $(($IPCOUNT+2)) > .generated_list
	sed -i '1d' .generated_list
	sed -i $(cat .generated_list | wc -l)d .generated_list
	cat .generated_list


	while true; do
    	read -p "Good ?" yn
    	case $yn in
        	[Yy]* ) return 0 ;;
        	[Nn]* ) ipPrechek;;
        	* ) echo "Please answer yes or no.";;
    	esac
	done


}




function ADDifcfg_Centos()
{
	printf "Already exist:\n"ip
	ls /etc/sysconfig/network-scripts/ifcfg-eth0* | ls  /etc/sysconfig/network-scripts/ifcfg-eth0* | tr '\n' '\n' | cut -c 38-



	if [ $(ls /etc/sysconfig/network-scripts/ifcfg-eth0* | tr '\n' '\n' | cut -c 38- | wc -l) == '1' ]
	then
		FROM=0
		TO=$(($(ls /etc/sysconfig/network-scripts/ifcfg-eth0* | tr '\n' '\n' | cut -c 38- | wc -l)+$IPCOUNT-2))
	else
		FROM=$(($(ls /etc/sysconfig/network-scripts/ifcfg-eth0* | tr '\n' '\n' | cut -c 38- | wc -l)-1))
		TO=$(($(ls /etc/sysconfig/network-scripts/ifcfg-eth0* | tr '\n' '\n' | cut -c 38- | wc -l)+$IPCOUNT-2))
	fi

	echo $FROM:$TO
	ip=1
	for i in $(seq $FROM $TO)
	do
		
		printf "DEVICE=eth0:${i}\nTYPE=Ethernet\nONBOOT=yes\nNM_CONTROLLED=yes\nBOOTPROTO=none\nIPADDR=$(sed -n ${ip}p .generated_list)\nNETMASK=255.255.255.255\n"  # > /etc/sysconfig/network-scripts/ifcfg-eth0:${i}
		ip=$(($ip+1))
	done
}




function ADDifcfg_Debian()
{
	if [ $(cat /etc/network/interfaces | grep "iface eth0" | wc -l) == '0' ]
	then
		FROM=0
		TO=$(($(cat /etc/network/interfaces | grep "iface eth0" | wc -l)+$IPCOUNT-1))
	else
		FROM=$(($(cat /etc/network/interfaces | grep "iface eth0" | wc -l)))
		TO=$(($(cat /etc/network/interfaces | grep "iface eth0" | wc -l)+$IPCOUNT-1))
	fi


	echo $FROM:$TO
	ip=1
	for i in $(seq $FROM $TO)
	do
		printf "\nauto eth0:${i}\niface eth0:${i} inet static\naddress=$(sed -n ${ip}p .generated_list)\nnetmask=255.255.255.255\n\n"  # > /etc/network/interfaces
		ip=$(($ip+1))
	done
	
}


function networkReload()
{
	while true; do
    read -p "Restart network? " yn
    case $yn in
        [Yy]* ) /etc/init.d/network restart; ip a; exit  ;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
	done
}


function clead()
{
	rm -f .iplist
	rm -f .generated_list
}




case $OS in
	"debian" )
		prepList
		ipPrechek 
		ADDifcfg_Debian
		clead
		networkReload
		;;
	"centos" )
		prepList
		ipPrechek 
		ADDifcfg_Centos
		clead
		networkReload
		;;
	* ) 
		clead
		exit
		;;		
esac
