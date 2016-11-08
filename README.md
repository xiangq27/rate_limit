# rate_limit

#start: sh limit.sh start 
#add:  sh limit.sh add classID rate srcIP dstIP stPORT
#update: sh limit.sh update classID rate srcIP dstIP stPORT
#remove: sh limit.sh remove classID rate srcIP dstIP stPORT
#show: sh limit.sh show 
#stop: sh limit.sh stop 

#set the param 
classID="$2"
SPEED="$3"
srcIP="$4" 
dstIP="$5" 
dstPort="$6"
