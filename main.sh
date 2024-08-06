#!/bin/bash
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color
token=$(sudo cat "${HOME}/humancheck/token.properties")
mchat=$(sudo cat "${HOME}/humancheck/mchat.properties")
#Ключи 
#'/Link' - получить ссылку на верификацию
#'/Data' - получить дату аутентификации
#'/Check' - для проверки времени до аутентификации
#
#
#
#
#

#функция проверки всех переменных бота и чата
function check_parametr
{
	sleep 1
	if [[ "${mchat}" < "1" ]] ; then
	echo "Не задан ИД чата! Введите ИД чата:"
	read mchat 
	echo -e $mchat	> "/root/humancheck/mchat.properties"
	fi
	sleep 1
	if [[ "${token}" < "1" ]] ; then
	echo "Не задан токен бота! Введите токен бота:"
	read token 
	echo -e $token	> "/root/humancheck/token.properties"
	fi
}

#вызов функции проверки всех переменных бота и чата
check_parametr

#функция которая принимает сообщения от бота
function get_update
{
for (( ;; )); do
var=$( curl -s https://api.telegram.org/bot$token/getUpdates )
text=$(echo "${var}" | jq -r ".result[0].message.text") 
update_id=$( echo "${var}" | jq -r ".result[0].update_id")
let "update_id=${update_id}+1"
chek_text=${text::1}
sleep 2
	if [ "$chek_text" = "/" ]; then
	
		if	 [ "$text" = "/Link" ]; then
		bash "/root/humancheck/humancheck.sh"  -'/Link'
		elif  [ "$text" = "/Data" ]; then
		bash "/root/humancheck/humancheck.sh"  -'/Data'
		fi
	else 
		echo $text
	fi
sleep 2
curl -s https://api.telegram.org/bot$token/getUpdates?offset=$update_id
done
} 


get_update &
for (( ;; )); do
#в цикле проверяем сколько часов осталось до аутентификации
bash "/root/humancheck/humancheck.sh"  -'/Check'
timehours=$(sudo cat "${HOME}/humancheck/time.properties")
echo -e "${GREEN} $timehours часов ${NC}"
#если времени меньше 2 часов переходим на поминутное сканирование
if [[ "${timehours}" = "1" ]] ; then
	datatoverif=$(curl -s -X POST http://localhost:9933  -H "Content-Type: application/json"  -d '{"jsonrpc": "2.0","id": 1,"method": "bioauth_status","params": []}'| jq -r .result.Active.expires_at)
		let "datatoverif=${datatoverif}/1000"
		datatoverif=$(TZ='Europe/Moscow' date -d @$datatoverif  +%s )
		sleep 1
		#поминутное сканирование
		for (( ;; )); do
		datenow=$(TZ='Europe/Moscow' date  +%s)
		let "DIFF=((${datatoverif} - ${datenow})/60)"
		echo  -e "${GREEN} $DIFF минут ${NC} " 
			#если меньше 5 минут
			if [[ "${DIFF}" = "5" ]] ; then
				curl -X POST -H 'Content-Type: application/json' -d '{"chat_id": "'"$mchat"'", "text": "Аутентификация начнется через 5 минут . Ссылку скоро получите" "disable_notification": false}' https://api.telegram.org/bot$token/sendMessage
			elif [[ "${DIFF}" = "1" ]] ; then
				curl -X POST -H 'Content-Type: application/json' -d '{"chat_id": "'"$mchat"'", "text": "До аутентификации 1 минута, через минуту пришлю ссылку" "disable_notification": false}' https://api.telegram.org/bot$token/sendMessage
				sleep 60
				bash "/root/humancheck/humancheck.sh"  -'/Link'
			elif [[ "${DIFF}" < "1" ]] ; then
				 sleep 300
				 bash "/root/humancheck/humancheck.sh"  -'/Check'
				 timehours=$(sudo cat "${HOME}/humancheck/time.properties")
					if   [[ "${timehours}" > "100" ]]; then
					curl -X POST -H 'Content-Type: application/json' -d '{"chat_id": "'"$mchat"'", "text": "Успех!" "disable_notification": false}' https://api.telegram.org/bot$token/sendMessage
					echo  -e "${GREEN} Успех! ${NC} " 
					break 1
					fi
			fi
		sleep 60
		done
fi	
sleep 3600
done
