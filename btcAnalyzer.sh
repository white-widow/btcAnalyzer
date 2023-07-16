#!/bin/bash

# Author: green-hawk

#Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

# tx hash curl -s "$unconfirmed_transactions" | grep -oP 'transactions/btc/\K[^"]+'
# btc amount curl -s "$unconfirmed_transactions" | grep -oP 'CUBz">\K[^ B]+'
# time curl -s "$unconfirmed_transactions" | grep -oP 'fFAyKv">\K[^<]+' | cut -d ' ' -f 2
# price dollar "$unconfirmed_transactions" | curl -s "https://www.blockchain.com/explorer/mempool/btc" | grep -oP '(?<=\$<!-- -->)[0-9.]+'

# senders -> curl -s "https://blockchair.com/bitcoin/transaction/"| awk '/Senders/,/Recipients/ {print}' | grep  -oP '(?<=recipient\":\").*?(?=\")'

trap ctrl_c INT

function ctrl_c(){
	echo -e "\n${redColour}[!]Getting out...\n${endColour}"

	rm ut.t* 2>/dev/null
	tput cnorm; exit 1

}

function helpPanel(){
	echo -e "\n${redColour}[!] Use: ./btcAnalyzer${endColour}"
	for i in $(seq 1 80); do echo -ne "${redColour}-"; done; echo -ne "${endColour}"
	echo -e "\n\n\t${grayColour}[-e]${endColour}${yellowColour} exploration mode ${endColour}"
	echo -e "\t\t${purpleColour}unconfirmed_transactions${endColour}${yellowColour}:\t list txs not confirmed ${endColour}"
	echo -e "\t\t${purpleColour}inspect${endColour}${yellowColour}:\t\t\t inspect a tx hash ${endColour}"
	echo -e "\t\t${purpleColour}address${endColour}${yellowColour}:\t\t\t inspect an address ${endColour}"
	echo -e "\n\t${grayColour}[-n]${endColour}${yellowColour} limit number of results${endColour}${blueColour} (Ex: -n 10)${endColour}"
	echo -e "\n\t${grayColour}[-h]${endColour}${yellowColour} show this help pannel ${endColour}\n"

	tput cnorm; exit 1
}

#global vars
unconfirmed_transactions="https://www.blockchain.com/explorer/mempool/btc"
inspect_transaction_url="https://www.blockchain.com/explorer/transactions/btc/"
inspect_address_url="https://www.blockchain.com/explorer/addresses/btc/"

function printTable(){

    local -r delimiter="${1}"
    local -r data="$(removeEmptyLines "${2}")"

    if [[ "${delimiter}" != '' && "$(isEmptyString "${data}")" = 'false' ]]
    then
        local -r numberOfLines="$(wc -l <<< "${data}")"

        if [[ "${numberOfLines}" -gt '0' ]]
        then
            local table=''
            local i=1

            for ((i = 1; i <= "${numberOfLines}"; i = i + 1))
            do
                local line=''
                line="$(sed "${i}q;d" <<< "${data}")"

                local numberOfColumns='0'
                numberOfColumns="$(awk -F "${delimiter}" '{print NF}' <<< "${line}")"

                if [[ "${i}" -eq '1' ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi

                table="${table}\n"

                local j=1

                for ((j = 1; j <= "${numberOfColumns}"; j = j + 1))
                do
                    table="${table}$(printf '#| %s' "$(cut -d "${delimiter}" -f "${j}" <<< "${line}")")"
                done

                table="${table}#|\n"

                if [[ "${i}" -eq '1' ]] || [[ "${numberOfLines}" -gt '1' && "${i}" -eq "${numberOfLines}" ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi
            done

            if [[ "$(isEmptyString "${table}")" = 'false' ]]
            then
                echo -e "${table}" | column -s '#' -t | awk '/^\+/{gsub(" ", "-", $0)}1'
            fi
        fi
    fi
}

function removeEmptyLines(){

    local -r content="${1}"
    echo -e "${content}" | sed '/^\s*$/d'
}

function repeatString(){

    local -r string="${1}"
    local -r numberToRepeat="${2}"

    if [[ "${string}" != '' && "${numberToRepeat}" =~ ^[1-9][0-9]*$ ]]
    then
        local -r result="$(printf "%${numberToRepeat}s")"
        echo -e "${result// /${string}}"
    fi
}

function isEmptyString(){

    local -r string="${1}"

    if [[ "$(trimString "${string}")" = '' ]]
    then
        echo 'true' && return 0
    fi

    echo 'false' && return 1
}

function trimString(){

    local -r string="${1}"
    sed 's,^[[:blank:]]*,,' <<< "${string}" | sed 's,[[:blank:]]*$,,'
}

function unconfirmedTransactions(){

	number_output=$1
	echo '' > ut.tmp
	echo '' > hash.tmp
	echo '' > btc.tmp
	echo '' > usd.tmp
	echo '' > timee.tmp

	if [ "$(cat timee.tmp | wc -l)" == "1" ]; then
		output=$(curl -s "https://www.blockchain.com/explorer/mempool/btc") && echo "$output" | grep -oP 'transactions/btc/\K[^"]+' > hash.tmp && echo "$output" | grep -oP 'CUBz">\K[^ B]+' > btc.tmp && echo "$output" | grep -oP '(?<=\$<!-- -->)[0-9.,]+' > usd.tmp && echo "$output" | grep -oP 'fFAyKv">\K[^<]+' > timee.tmp
	fi

	paste -d '\n' hash.tmp btc.tmp usd.tmp timee.tmp > ut.tmp 2>/dev/null
	rm -r hash.tmp btc.tmp usd.tmp timee.tmp 2>/dev/null

	#re-order

	hashes=$(cat ut.tmp | grep -E '^[[:xdigit:]]{64}$' | head -n $number_output)

	#for hash in $hashes; do
	#	echo $hash
	#done

	echo -ne "${yellowColour}"
	echo "Hash_USD_BTC_Time" > ut.table

	amount=0

	for hash in $hashes; do 
		echo ${hash}_$(cat ut.tmp | grep "$hash" -A 2 | tail -n 1)_$(cat ut.tmp | grep "$hash" -A 1 | tail -n 1)_$(cat ut.tmp | grep "$hash" -A 3 | tail -n 1) >> ut.table
		value=$(cat ut.tmp | grep "$hash" -A 1 | tail -n 1)
		amount=$(echo "$amount + $value" | bc)
	done

	printTable '_' "$(cat ut.table)"

	echo -ne "${endColour}"
	echo -ne "${blueColour}"

	total="Total_${amount}"

	printTable '_' $total

	echo -ne "${endColour}"

	rm ut.t* 2>/dev/null
	tput cnorm
}

function inspectTx(){

	tx_hash=$1

	# senders -> curl -s "https://blockchair.com/bitcoin/transaction/"| awk '/Senders/,/Recipients/ {print}' | grep  -oP '(?<=recipient\":\").*?(?=\")'

	output=$(curl -s "https://blockchair.com/bitcoin/transaction/$tx_hash" | html2text) && echo "$output" | awk '/Sender/,/Recipient/ {print}' | grep -oP '(?<=recipient\":\").*?(?=")' > addresses.tmp && echo "$output" | awk '/Sender/,/Recipient/ {print}' | grep  -oP '(?<=____).*?(?=BTC)' > amounts.tmp

	paste -d '\n' addresses.tmp amounts.tmp > spenders.tmp 

	rm -r addresses.tmp amounts.tmp 2>/dev/null

	spenders=$(cat spenders.tmp | grep -P '[a-zA-Z]')

	amount=0

	echo "spender_amount" > ut.table

	for spender in $spenders; do
		echo ${spender}_$(cat spenders.tmp | grep "$spender" -A 1 | tail -n 1 | grep -o '[^[:space:]]*') >> ut.table
		value=$(cat spenders.tmp | grep "$spender" -A 1 | tail -n 1 | grep -P '[0-9]')
		amount=$(echo "$amount + $value" | tr -d '\302\240' | bc)
	done

	echo "Total_${amount}" >> ut.table

	printTable '_' "$(cat ut.table)"

	rm *.tmp 2>/dev/null
	rm ut.table 2>/dev/null

	tput cnorm
}

parameter_counter=0;

while getopts "e:n:i:h" arg; do
	case $arg in
		e) exploration_mode=$OPTARG; let parameter_counter+=1;;
		n) number_output=$OPTARG; let parameter_counter+=1;;
		i) tx_hash=$OPTARG; let parameter_counter+=1;;
		h) helpPanel;;
	esac
done

tput civis

if [ $parameter_counter -eq 0 ]; then
	helpPanel
else
	if [ "$(echo $exploration_mode)" == "unconfirmed_transactions" ]; then
		if [ ! "$number_output" ]; then
			number_output=18
			unconfirmedTransactions $number_output
		else
			unconfirmedTransactions $number_output
		fi
	fi

	if [ "$(echo $exploration_mode)" == "inspect" ]; then
		inspectTx $tx_hash
	fi
fi
