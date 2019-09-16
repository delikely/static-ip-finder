#!/bin/bash
# Author: delikely
# Date: 2019/9/10
# Description：在很多场景中，能与IOT设备通过网线直连，但是不知道IOT设备的IP地址，此脚本用于发现C段的对端IOT设备的静态IP。另一种获取方法是，PC直连IOT设备后，重启IOT设备，在PC端抓包过滤ARP包（arp.isgratuitous == 1） ,利用在静态IP生效之前需要探测是否存在冲突（重复）。
# Dependece: arp-scan

ProgressBar()
{
  local current=$1; local total=$2
  local now=$((current*100/total))
  local last=$(((current-1)*100/total))
  [[ $((last % 2)) -eq 1 ]]&&let last++
  local str=$(for i in `seq 1 $((last/2))`; do printf '#'; done)
  for ((i=$last;$i<=$now;i+=2));do
	  printf "\r\e[32m[%-50s]%d%%\e[0m" "$str"  $i;str+='#';
  done
}


FindIP(){
	prefix_ip=$2"."

	echo "BEGIN AT: "`date`
	for i in `seq 0 255`
	do
		ip=$prefix_ip$i".233"
		ifconfig $1 $ip netmask "255.255.255.0"
		arp_scan_result=`arp-scan --interface eth0 --localnet`
		echo "$arp_scan_result"|grep "0 packets received" > /dev/null
		if [ $? -eq 1 ];then
			printf "\n"
			echo "$arp_scan_result" |grep $prefix_ip
		fi
		ProgressBar $i 256
	#	break
	done
	printf "\n"
	echo "FINISH AT: "`date`
}

usage(){
	cat <<EOF 
Usage: IOT-IP-Finder [options]
	-i <interface>: Use network interface 
	-p <prefix>: The pefix of ip address 
	
	Example: sudo static-ip-finder -i eth0 -p 192.168
EOF
	exit 1 
}



while getopts "i:p:h" opt;
do
	case $opt in
		h)
			usage
			exit
			;;
		i)
			interface=$OPTARG
			;;
		p)
			prefix=$OPTARG
			;;
		?)
			usage
			;;
	esac
done


#设置默认参数
if [ "$interface"x = ""x ];then
	interface="eth0"
fi

if [ "$prefix"x = ""x ];then
	prefix="192.168"
fi

FindIP $interface $prefix
