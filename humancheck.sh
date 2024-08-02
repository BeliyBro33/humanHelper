#!/bin/bash
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color
sleep 1
mchat=$(sudo cat "${HOME}/humancheck/mchat.properties")
schat='-1001500189369'
token=$(sudo cat "${HOME}/humancheck/token.properties")
name=$(sudo cat "${HOME}/.humanode/workspaces/default/workspace.json" | jq -r .nodename)
ip=$(wget -qO - eth0.me)

#функция отправки сообщений
function sendMessage()
{
if [[ "${1}" = "1" ]]; then
	curl -X POST -H 'Content-Type: application/json' -d '{"chat_id": "'"$mchat"'", "text": "Аутентификация не пройдена!" "disable_notification": false}' https://api.telegram.org/bot$token/sendMessage
		sleep 1
		send_verif_link
elif  [[ "${1}" = "2" ]] ; then
	curl -X POST -H 'Content-Type: application/json' -d '{"chat_id": "'"$schat"'", "text": "Тревога! Тревога! Волк унес зайчат (статус не получен) '"$ip"' '"$name"'" "disable_notification": false}' https://api.telegram.org/bot$token/sendMessage
elif  [[ "${1}" = "3" ]] ; then
	timeverif=$(curl -s -X POST http://localhost:9933  -H "Content-Type: application/json"  -d '{"jsonrpc": "2.0","id": 1,"method": "bioauth_status","params": []}'| jq -r .result.Active.expires_at)
	let "timeverif=${timeverif}/1000"
	timeverif=$(TZ='Europe/Moscow' date -d @$timeverif   +%d%t%B%t%T )
	curl -X POST -H 'Content-Type: application/json' -d '{"chat_id": "'"$schat"'", "text": "Следующая аутентификации будет '"$timeverif"'" "disable_notification": false}' https://api.telegram.org/bot$token/sendMessage
fi
}

#функция проверки времени до аутентификации
function  time_do_verif
{
	datatoverif=$(curl -s -X POST http://localhost:9933  -H "Content-Type: application/json"  -d '{"jsonrpc": "2.0","id": 1,"method": "bioauth_status","params": []}'| jq -r .result)
	if [[ "${datatoverif}" = "Inactive" ]] ; then
		message=1
		sendMessage $message
	elif  [[ "${datatoverif}" < "1" ]] ; then
		message=2
		sendMessage $message
	else 
		datatoverif=$(curl -s -X POST http://localhost:9933  -H "Content-Type: application/json"  -d '{"jsonrpc": "2.0","id": 1,"method": "bioauth_status","params": []}'| jq -r .result.Active.expires_at)
		let "datatoverif=${datatoverif}/1000"
		datatoverif=$(TZ='Europe/Moscow' date -d @$datatoverif  +%s )
		sleep 1
		datenow=$(TZ='Europe/Moscow' date  +%s)
		let "DIFF=((${datatoverif} - ${datenow})/3600)" #60 -минут 3600 -часов
		echo $DIFF " часов"
	fi
}

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

#функция для отправки ссылки на утентификацию
function send_verif_link
{
cd "/root/.humanode/workspaces/default/"
link=$(./humanode-peer bioauth  auth-url --rpc-url-ngrok-detect --chain chainspec.json) 
	curl -X POST -H 'Content-Type: application/json' -d '{"chat_id": "'"$mchat"'", "text": "Cсылка на аутентификацию - '"$link"'" "disable_notification": false}' https://api.telegram.org/bot$token/sendMessage
}
# функция для тестирования
function test
{
mes=123
curl -X POST -H 'Content-Type: application/json' -d '{"chat_id": "-1001500189369", "text": "'"$mes"'": false}' https://api.telegram.org/bot5434189022:AAFRApdxpp9kahgO5C6OTUyyxxBarEqSUnU/sendMessage
}
#вызов функции проверки всех переменных бота и чата
check_parametr
#цикл
#for (( ;; )); do
#вызов функции



case "$1" in 
-'/КогдаВериф?') sendMessage 3;;
-'/Ссылка') send_verif_link;;
*) echo bezkey;;
esac

sleep 2
#done
