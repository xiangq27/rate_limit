#!/bin/bash 

#start: sh limit.sh start 
#add:  sh limit.sh add classID rate srcIP dstIP stPORT
#update: sh limit.sh update classID rate srcIP dstIP stPORT
#remove: sh limit.sh remove classID rate srcIP dstIP stPORT
#show: sh limit.sh show 
#stop: sh limit.sh stop 
#test:

#set the param 
classID="$2"
SPEED="$3"
srcIP="$4" 
dstIP="$5" 
dstPort="$6"

#start: to delete existing disc rules 
start () {

	iflist=$(ifconfig -a | sed 's/[ \t].*//;/^$/d')
	for if in ${iflist[@]}
	do
		echo $if
	#first, delete existing disc rules 
		tc qdisc del dev $if root 
	#tc qdisc del dev eth0 root
	#show the current rules
		tc -s qdisc ls dev $if
	#define the top queue discplines and assign default class number
		tc qdisc add dev $if root handle 1: htb
	done
	#tc qdisc add dev wth0 root handle 1: cbq bandwidth TOTALMbit avpkt 1000 cell 8 mpu 64
	#tc class add dev eth0 parent 1:0 classaid 1:1 cbq bandwidth TOTALMbit rate TOTALMbit maxburst 20 allot 1514 avpkt 1000
	#tc filter add dev eth0 parent 1:0 protocol ip prio 100 route
} 

add() { 
	if=$(ifconfig | grep -B1 addr:$srcIP | awk '$1!="inet" && $1!="--" {print $1}')
	tc class add dev $if parent 1: classid 1:$classID htb rate $SPEED'mbps' ceil $SPEED'mbps'

	#iensure fairness, add a randoem fair queue
	#TODO: ???what is this used for??? tc qdisc add dev eth0 parent 1:$classID handle $classID: sfq perturb 10

	tc filter add dev $if protocol ip parent 1: prio 1 u32 match ip src $srcIP \
	match ip dst $dstIP match ip dport $dstPort 0xffff flowid 1:$classID	
	#???	iptables -A OUTPUT -t mangle -p tcp --sport $dstPort -j MARK --set-mark 10
} 

update() {
	if=$(ifconfig | grep -B1 addr:$srcIP | awk '$1!="inet" && $1!="--" {print $1}')
	tc class change dev $if parent 1: classid 1:$classID htb rate $SPEED'mbps' ceil $SPEED'mbps'
	#maxburst 20 allot 1514 avpkt 10000 
} 

remove() {
	if=$(ifconfig | grep -B1 addr:$srcIP | awk '$1!="inet" && $1!="--" {print $1}')
	line=$(tc filter show dev eth0 | grep 1:$classID --color=never)
	fhpos=$(tc filter show dev eth0 | grep 1:$classID --color=never | grep -aob "fh" --color=never | grep -oE '[0-9]+')
	orderpos=$(tc filter show dev eth0 | grep 1:$classID --color=never | grep -aob "order" --color=never | grep -oE '[0-9]+')
	fh=${line:$fhpos+3:$orderpos-$fhpos-4}
	tc filter del dev $if parent 1: proto ip prio 1 handle $fh u32
	tc class del dev $if classid 1:$classID
#	tc class del dev eth0 parent 1:1 classid 1:$classID htb rate $SPEED'mbps' ceil $SPEED'mbps' prio 2
#	echo done deleting class

} 

show(){
	iflist=$(ifconfig -a | sed 's/[ \t].*//;/^$/d')
	for if in ${iflist[@]}
	do
		echo $if
	#show the queue situation 
		tc -s qdisc ls dev $if 
	#show class situation 
		tc class ls dev $if
	#show filter situation 
		tc -s filter ls dev $if
	done
} 


debug(){
	tmp=$(ifconfig -a | sed 's/[ \t].*//;/^$/d')
	for i in ${tmp[@]}
	do
		echo $i
	done
}

stop () {
	iflist=$(ifconfig -a | sed 's/[ \t].*//;/^$/d')
	for if in ${iflist[@]}
	do
		echo $if
		tc qdisc del dev $if root 
	done
}


case "$1" in 
    	start)
		start 
		;;
	debug)
		debug	
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




