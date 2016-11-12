#start: sh limit.sh start 
#add:  sh limit.sh add classID rate srcIP dstIP stPORT
#update: sh limit.sh update classID rate srcIP dstIP stPORT
#remove: sh limit.sh remove classID rate srcIP dstIP stPORT
#show: sh limit.sh show 
#stop: sh limit.sh stop 

#!/bin/bash 
#set the param 
classID="$2"
SPEED="$3"
srcIP="$4" 
dstIP="$5" 
dstPort="$6"

#start: to delete existing disc rules 
start () { 
	#first, delete existing disc rules 
	tc qdisc del dev eth0 root 2> /dev/null > /dev/null
	#tc qdisc del dev eth0 root
	#show the current rules
	tc -s qdisc ls dev eth0
	#define the top queue discplines and assign default class number
	tc qdisc add dev eth0 root handle 1: htb default 2
	
	#tc qdisc add dev wth0 root handle 1: cbq bandwidth TOTALMbit avpkt 1000 cell 8 mpu 64
	#tc class add dev eth0 parent 1:0 classaid 1:1 cbq bandwidth TOTALMbit rate TOTALMbit maxburst 20 allot 1514 avpkt 1000
	#tc filter add dev eth0 parent 1:0 protocol ip prio 100 route
} 

add() { 
	#echo $classID
	#define 1:1 class and rate,ceil maximum bandwidth
	tc class add dev eth0 parent 1:1 classid 1:$classID htb rate $SPEED'mbps' ceil $SPEED'mbps' prio 2
	#iensure fairness, add a randoem fair queue
	tc qdisc add dev eth0 parent 1:$classID handle $classID: sfq perturb 10
	#set a filter, use iptable to mark, assign that class root 1:0, use i:classID rule to set a rate
	tc filter add dev eth0 protocol ip parent 1:0 u32 match ip src $srcIP flowid 1:$classID
	iptables -A OUTPUT -t mangle -p tcp --sport $dstPort -j MARK --set-mark 10

	#tc qdisc add dev eth0 root handle 1:0 htb
	#tc class add dev eth0 parent 1:1 htb classid 1:$classID htb rate $SPEEDMbit ceil $TOTALMbit
	
	#tc qdisc add dev eth0 root handle 1: tbf rate $SPEEDMbit burst maxburst 20 allot 1514 avpkt 1000
	#tc class add dev eth0 parent 1:1 classid 1:$classID cbq rate $SPEEDMbit maxburst 20 allot 1514 avpkt 1000
	#tc filter add dev eth0 parent 1:0 protocol ip prio 100 route to classID flowid 1:$classID
	#ip route add $dstIP dev eth0 via $srcIP realm $classID
} 

update() { 
	tc class change dev eth0 parent 1:1 classid 1:$classID htb bandwidth $SPEED'Mbit' rate $SPEED'Mbit' maxburst 20 allot 1514 avpkt 10000 
} 

remove() { 
	tc class del dev eth0 parent 1:$classID handle $classID: sfq perturb 10
	tc filter del dev eth0 parent protocol ip parent 1:0 u32 match ip src $srcIP flowid 1:$classID
} 

show(){ 
	#show the queue situation 
	tc -s qdisc ls dev eth0 
#show class situation 
	tc class ls dev eth0 
#show filter situation 
	tc -s filter ls dev eth0 
} 

stop () { 
	tc qdisc del dev eth0 root 
} 

case "$1" in 
    start)
		start 
		;;
	add)
		add
		;;
	update)
		update
		;; 
	remove)
		remove
		;;
	show)
		show
		;; 
	stop)
		stop
		;; 
	*)
	echo "Usage: `basename $0` {start|add|update|remove|show|stop} speed(gb/s)"
esac 




