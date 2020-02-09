#!/bin/bash
# CHORFA Alla-eddine
# h4ckr213dz@gmail.com
# Version 1.0
# creation 25.01.2020
#######################################

#default params
self="$0"
target="www.revesdorient.fr";
type="2";
endpoint='/wp/v2/users'
url_lst_src='./wpApiRestTester.endpoints'
tempFile='/tmp/jsonformat.tmp'
outfolder='output'
useragent='Mozilla/5.0 (MSIE 10.0; Windows NT 6.1; Trident/5.0)'
auth=''

c_main='\033[33;1m'
c_text='\033[36;1m'
c_json='\033[35;1m'
c_symbols='\033[34;1m'

#functions

function showHelp {
	echo -e "HELP:"

	echo -e "\nSYNTAX:"
	echo -e "\t $self [-h] [-v] [-u url] [e endpoint] [ t type]"

	echo -e "\nTYPES:"
	echo -e "\t 1 : The targets API is in located in /wp-json"
	echo -e "\t 2 : The targets API is in located in /"

	echo -e "\nENDPOINTS:"

	echo -e "\nEXAMPLES:"
	echo -e "\t Show help: $self -h"
	echo -e "\t Simples request: $self -u http://example.com/"
	echo -e "\t verbose mode: $self -v -u http://example.com/"
	echo -e "\t set endpoint filter: $self -u http://example.com/ -e users"
	echo -e "\t set set request type:"
	echo -e "\t\t Type 1 : $self -u http://example.com/ -e users -t 1 "
	echo -e "\t\t          the targets api is in located in /wp-json"
	echo -e "\t\t Type 2 : $self -u http://example.com/ -e users -t 2 "
	echo -e "\t\t          the targets api is in located in /"
	}
function checkTarget {
	this_target="$1"
	this_revtarget=$(echo "$this_target"|rev)
	this_target_size=${#this_target}
	this_revtarget_size=$(( $this_target_size-1 ))

	if [ "${this_revtarget:0:1}" = "/" ];then
		this_revtarget=${this_revtarget:1:$this_revtarget_size}
		this_target=$(echo "$this_revtarget"|rev)
		this_target="$this_target"
	fi
	if [ "${this_target:0:4}" != "http" ];then
		this_target="http://$this_target"
	fi
	
	echo "$this_target"
	}

function checkType {
	this_type="$1"
	
	if [ $this_type -ne 1 ] && [ $this_type -ne 2 ];then
		this_type=1
	fi
	
	echo "$this_type"
	}

function checkJsonFormat {
	this_logFilename="$1"
	this_check_ifJson_c1=$(cat $this_logFilename|grep -i '<!DOCTYPE html>')
	this_check_ifJson_c2=$(cat $this_logFilename|grep -i '<html>')
	if [ ${#this_check_ifJson_c1}  -gt 0 ] || [ ${#this_check_ifJson_c2}  -gt 0 ];then
		this_isJson='false'
	else
		this_isJson='true'

	fi

	echo "$this_isJson"
	}

function getUrlListByType {
	this_type="$1"
	this_url_lst_src="$2"
	this_endpoint="$3"
	this_url_list=""

	if [ "$this_type" = "1" ];then
		#this_url_list=$(cat "$this_url_lst_src"|grep -i "$this_endpoint" | egrep -iv "^/wp-json")
		this_url_list=$(cat "$this_url_lst_src"|grep -i "$this_endpoint")
	else
		#this_url_list=$(cat "$this_url_lst_src"|grep -i "$this_endpoint" |egrep -i "^/wp-json")
		this_url_list=$(cat "$this_url_lst_src"|sed "s/^/\/wp-json/g"|grep -i "$this_endpoint")
	fi

	echo "$this_url_list"
	}

function getLogFilename {
	this_target="$1"
	this_url="$2"

	this_logFilename_p1=${this_target//*:\/\//}
	this_logFilename_p1=${this_logFilename_p1//[\\:,;-]/}
	this_logFilename_p1=${this_logFilename_p1//[\/]/.}
	this_logFilename_p2=${this_url//[\\:,;-]/}
	this_logFilename_p2=${this_logFilename_p2//[\/]/.}
	this_logFilename_p2=${this_logFilename_p2//\?/P}
	this_logFilename='./'"$outfolder"'/'"$this_logFilename_p1"''"$this_logFilename_p2"'.json'

	echo "$this_logFilename"
	}

function consoleShowError {
	this_label="$1"
	this_message="$2"
	this_nbtabs="$3"
	this_nl="$4"
	this_puce="[!]"

	if [ "$this_nbtabs" = '' ];then
		this_nbtabs=0
	fi

	if [ "$this_nl" != '' ];then
		this_nl='-n'
	fi

	if [ $this_nbtabs -ne 0 ];then
		this_puce="|_[-]"
	fi

	this_tabs=""$(perl -E 'say " " x '$this_nbtabs'' )""
	
	this_message_formatted="$c_main$this_tabs$this_puce $this_label:\033[31;1m $this_message"

	echo -e $this_nl "$this_message_formatted"
	}

function consoleShowMessage {
	this_label="$1"
	this_message="$2"
	this_nbtabs="$3"
	this_nl="$4"
	this_puce="[+]"

	if [ "$this_nbtabs" = '' ];then
		this_nbtabs=0
	fi

	if [ "$this_nl" != '' ];then
		this_nl='-n'
	fi

	if [ $this_nbtabs -ne 0 ];then
		this_puce="|_[-]"
	fi

	this_tabs=""$(perl -E 'say " " x '$this_nbtabs'' )""
	
	this_message_formatted="$c_main$this_tabs$this_puce $this_label:$c_text $this_message"

	echo -e $this_nl "$this_message_formatted"
	}

function colorizeJsonLine {
	this_line="$1"
	this_newline="$this_line"

	this_symbols=('"' ':' ',' '{' '}' ']' '\\\[' )
	
	co=$c_json
	cn=$c_symbols
	
	this_newline=${this_newline//:\/\//@@@@}

	for symb in ${this_symbols[*]};do
		this_newline=${this_newline//$symb/$cn${symb/@/s}$co}	
	done

	this_newline=${this_newline//@@@@/:\/\/}	

	echo -E "$this_newline"
	}

function formatJsonResult {
	this_json_source="$1"
	this_checkEmptyJson=$(cat "$this_json_source")
	this_nb_marge=1
	this_marge=''
	
	#formattage de l'arbre d'abo selon sa position (dernier ou pas)
	if [ "$2" != "" ];then
		this_arbre="    |"
		dec=1
	else
		this_arbre=" |  |"
		dec=1
	fi

	echo -en "$c_json"
	#si le resultat JSON n'est pas vide
	if [ "$this_checkEmptyJson" != "[]" ];then
		#creer un ficher temp avec un premier formattage : ponctuation
		echo -n '' > "$tempFile"
		for a_line in $(cat "$this_json_source"|sed "s/ /%20/g");do
			a_line=${a_line//'",'/'",\n'}
			a_line=${a_line//{/{\\n}
			a_line=${a_line//\}/\\n\}}
			a_line=${a_line//\[/\[\\n}
			a_line=${a_line//\]/\\n\]}
			echo -e "$a_line" >> "$tempFile"
		done
		#on commence le formattage des champs
		total_lines=$(cat "$tempFile"|wc -l)
		nb_lines=0

		#on commence le formattage des champs
		for t_line in $(cat "$tempFile");do
			#calcul marge affichage
			nb_lines=$(( $nb_lines+1 ))
			this_marge=""$(perl -E 'say "   " x '${this_nb_marge}'' )
			
			#condition d'ajout d'une marge : accolade ouverte, virgule...etc
			if [[ "$t_line" =~ '{' ]] || [[ "$t_line" =~ '[' ]];then
				this_nb_marge=$(( $this_nb_marge+1 ))
			fi			
			
			#colorisation syntaxique
			t_line=$(colorizeJsonLine "$t_line")			
	
			#on remet les espaces : apres formattage
			t_line=${t_line//%20/ }
			t_line=${t_line//\\\//\/}

			#affichage de la derniere ligne: ajout d'une ligne explicitant la fin des resultats
			if [ $nb_lines -eq $(($total_lines-$dec+1)) ];then
				echo -e "$c_main$this_arbre$this_marge$t_line"
				echo -e "$c_main${this_arbre}____________________________________________________________________________/"
			else
				echo -e "$c_main$this_arbre$this_marge$t_line"
			fi

			#condition de retrait d'une marge : accolade fermee, ...etc
			if [[ "$t_line" =~ '}' ]] ||  [[ "$t_line" =~ ']' ]];then
				this_nb_marge=$(( $this_nb_marge-1 ))
			fi
		done
	#si le resultat JSON est vide
	else
		for s_line in $(cat "$this_json_source"|sed "s/ /%20/g");do
			echo -e "\t$s_line"
		done
	fi

	}

#options and args
options=''
while getopts 'hva:u:e:t:' flag; do
  case "${flag}" in
    h) 	options=$options'help ';
	showHelp;
       	exit 1;;
    v) 	options=$options'verbose ' ;;
    a) 	options=$options'authentication ';
       	auth="${OPTARG}";;
    u) 	options=$options'target ';
       	target="${OPTARG}" ;;
    e) 	options=$options'endpoint ';
       	endpoint="${OPTARG}" ;;
    t) 	options=$options'target ';
       	type="${OPTARG}" ;;
    *) 	options=$options'unknown ';
	showHelp;
       	exit 1 ;;
  esac
done


#check target
target=$(checkTarget "$target")
type=$(checkType "$type")

#get URL lyst by type
url_list=$(getUrlListByType "$type" "$url_lst_src" "$endpoint")

#nb requests
total_requests=$(echo "$url_list"|wc -l)
nb_requests=0

#check auth
if [ "$auth" != "" ];then
	auth_param='--basic '$auth'';
else
	auth_param='';
fi


#show params and infos
#clear
consoleShowMessage "Options" "$options"
consoleShowMessage "Target" "$target"
consoleShowMessage "Endpoint" "$endpoint" 
consoleShowMessage "API Type" "V$type"
consoleShowMessage "Total queries" "$total_requests"

if [ "$auth" != "" ];then
	consoleShowMessage "Authentication" "$auth_param"
fi

#start requests
consoleShowMessage "Sending API Requests"
for url in $url_list;do 
	nb_requests=$(( $nb_requests+1 ))
	mkdir "./$outfolder" 2>/dev/null  1>/dev/null
	logFilename=$(getLogFilename "$target" "$url")

	consoleShowMessage "QUERY n°" "$nb_requests/$total_requests" "1"
	consoleShowMessage "LOGFILE" "$logFilename" "1"
	consoleShowMessage "FORGED URL" "$target$url" "1"
	curl -ks "$target$url" -o "$logFilename" $auth_param -A "$useragent"
	consoleShowMessage "RESULT" "" "1"
	check_ifJson=$(checkJsonFormat "$logFilename")

	if [ "$check_ifJson" = "true" ];then
		if [ $nb_requests -ne $total_requests ];then
			formatJsonResult "$logFilename"	
		else
			formatJsonResult "$logFilename"	"end"
		fi	
	else
		consoleShowError "ERROR" "HTML not JSON response" "4"
	fi
done

echo -e "\033[0m"
exit 0
