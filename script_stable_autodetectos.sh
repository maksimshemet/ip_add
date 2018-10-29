#!/bin/bash


if [ -f /usr/bin/apt ]
then

OS="debian"

else

OS="centos"

fi

read -p  "Count of ip?" IPCOUNT
ip=0

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


function neIPselect()
{

ip=$(whiptail --title "Subnets" --radiolist \
#ip

          3>&1 1>&2 2>&3)


fping -q -g -u $ip > .generated_list
while read LINE
do
        array+=($LINE)
        array+=("")
        array+=("off")
done < .generated_list

var=$(whiptail --title "IP" --checklist "choose IPs" 16 78 10 "${array[@]}" 3>&1 1>&2 2>&3)
echo $var | sed s/'"'//g | sed 's/ /\n/g' > .generated_list

cat .generated_list
while true; do
    	read -p "Correct IPs ?" yn
    	case $yn in
        	[Yy]* ) return 0 ;;
        	[Nn]* ) neIPselect;;
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
		
		printf "DEVICE=eth0:${i}\nTYPE=Ethernet\nONBOOT=yes\nNM_CONTROLLED=yes\nBOOTPROTO=none\nIPADDR=$(sed -n ${ip}p .generated_list)\nNETMASK=255.255.255.255\n"   > /etc/sysconfig/network-scripts/ifcfg-eth0:${i}
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
		printf "\nauto eth0:${i}\niface eth0:${i} inet static\naddress $(sed -n ${ip}p .generated_list)\nnetmask 255.255.255.255\n\n"   >> /etc/network/interfaces
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


function networkReloadDeb()
{
	while true; do
    read -p "Restart networking? " yn
    case $yn in
        [Yy]* ) /etc/init.d/network restart; ip a; exit  ;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
	done
}

function clead()
{
	rm -f .ip
	rm -f .generated_list
	rm -f $0
}

function genTicket()
{
	printf "

########################################### TICKET ##########################################

Hello,
If ip was used before please re-use

Additional IPs:
$(cat .generated_list)

Main VPS ip - $(curl -s 2ip.ru)
VPS Name is $(hostname) 




" 
}




case $OS in
	"debian" )
		apt -y install fping
		neIPselect
		ADDifcfg_Debian
		genTicket
		clead
		networkReloadDeb
		;;
	"centos" )
		yum -y install fping
		neIPselect 
		ADDifcfg_Centos
		genTicket
		clead
		networkReload
		;;
	* ) 
		clead
		exit
		;;		
esac
