#!/bin/bash
#==================================================================================
#  problem1.sh
#  Created by JRH on 12/13/2015
#
#
#  This scripts was designed to parse through SYSCONFIG file to capture JSON format
#
#
#  
#
# Uncomment to debug
#set -x
#==================================================================================
# help
#==================================================================================
help() {
   printf "The proper syntax is: \n"
   printf "./problem1.sh /path/to/file/to/parse.txt \n"
   printf "example: \n"
   printf "./problem1.sh data/SYSCONFIG-A.1.txt \n"
   exit 1
}
#==================================================================================
# SET VARIABLES AND VALIDATE INPUT
#==================================================================================
if [ -z "$1" ]; then help;
else
:
fi
CONFIG=$1
OUTPUT=${CONFIG}.output
#==================================================================================
# MAIN
#==================================================================================
# Start the JSON output
printf "{" >$OUTPUT

# Capture system serial and model number
SERIAL=`cat $CONFIG |grep 'System Serial Number' |cut -d":" -f2|awk '{print $1}'`
MODEL=`cat $CONFIG |grep 'Model Name' |cut -d":" -f2|tr -d '[[:space:]]'`

# Output model and serial to JSON
printf "'model': '$MODEL', 'serial': '$SERIAL', " >>$OUTPUT

# Begin PCI Card capture
# Start PCI Card JSON output
printf "'PCICards': {" >> $OUTPUT
OIFS=$IFS
IFS='
'
# Capture last slot in the loop
LASTSLOT=`cat $CONFIG |grep slot|grep -v 'slot 0'|awk '{print $1,$2}'|sed -e 's|:||g'|sort -u|tail -n1`

# Get PCI Cards and output in JSON
for SLOTS in `cat $CONFIG |grep slot|grep -v 'slot 0'|awk '{print $1,$2}'|sed -e 's|:||g'|sort -u`
do
SLOTNUM=`echo "${SLOTS}"|awk '{print $2}'`
printf "'${SLOTNUM}': " >> $OUTPUT
PCICARD=`cat $CONFIG |grep "$SLOTS" |head -n1|cut -d":" -f2| sed -e 's/^[ \t]*//'`
if [[ "${SLOTS}" == "${LASTSLOT}" ]];then
printf "'$PCICARD'}, " >> $OUTPUT
else
printf "'$PCICARD', " >> $OUTPUT
fi
done

# Begin loop for drives per slot
# Start JSON output
printf "'disks_per_port': {" >> $OUTPUT
# Capture Slots in an array
ALLPORTS=`cat data/SYSCONFIG-A.1.txt|grep 'slot'|grep 'Host Adapter'|awk '{print $6}'`
PORTARRAY=( $ALLPORTS )
LASTPORT=`echo ${PORTARRAY[@]:(-1)}`
tLen=${#PORTARRAY[@]}
for (( i=0; i<${tLen}; i++))
do 
THISPORT=`echo ${PORTARRAY[$i]}`
if [[ ${PORTARRAY[$i]} == ${LASTPORT} ]];then
OIFS=$IFS
IFS='
'
NUMOFDISKS=`awk "/Adapter ${PORTARRAY[$i]}/ { show=1 } show; /END/ { show=0 }" $CONFIG|grep NETAPP|wc -l`
else
NUMOFDISKS=`awk "/Adapter ${PORTARRAY[$i]}/ { show=1 } show; /Adapter ${PORTARRAY[$i+1]}/ { show=0 }" $CONFIG|grep NETAPP|wc -l`
fi
if [[ ! $NUMOFDISKS -eq 0 ]];then
if [[ "${THISPORT}" == "${PORTARRAY[0]}" ]];then
printf "'$THISPORT': '$NUMOFDISKS'" >> $OUTPUT
else
printf ", '$THISPORT': '$NUMOFDISKS'" >> $OUTPUT
fi
fi
done
# Close number of disks JSON
printf "}" >> $OUTPUT
# Close the full JSON
printf "} \n" >> $OUTPUT
