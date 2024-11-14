#!/bin/bash

while :
do

game1=`ps aux | grep /data/server1/game/p8_app_server | grep -v grep`
if [ "$?" != "0" ];
then
echo "game1-restart" | awk '{ print $0"\t" strftime("%Y-%m-%d %H:%M:%S",systime()) }' >> /data/tool/dump.txt &
cd /data/server1/game/
cp -f nohup.txt /data/logback/nohup_game1_$(date +%Y%m%d%H%M%S).txt 
rm -rf nohup.txt 
./server.sh start &
else
echo "game1-isruning" | awk '{ print $0"\t" strftime("%Y-%m-%d %H:%M:%S",systime()) }' >> /data/tool/control.txt &
fi
sleep 5s

game2=`ps aux | grep /data/server2/game/p8_app_server | grep -v grep`
if [ "$?" != "0" ];
then
echo "game2-restart" | awk '{ print $0"\t" strftime("%Y-%m-%d %H:%M:%S",systime()) }' >> /data/tool/dump.txt &
cd /data/server2/game/
cp -f nohup.txt /data/logback/nohup_game2_$(date +%Y%m%d%H%M%S).txt 
rm -rf nohup.txt 
./server.sh start &
else
echo "game2-isruning" | awk '{ print $0"\t" strftime("%Y-%m-%d %H:%M:%S",systime()) }' >> /data/tool/control.txt &
fi
sleep 5s

game3=`ps aux | grep /data/server3/game/p8_app_server | grep -v grep`
if [ "$?" != "0" ];
then
echo "game3-restart" | awk '{ print $0"\t" strftime("%Y-%m-%d %H:%M:%S",systime()) }' >> /data/tool/dump.txt &
cd /data/server3/game/
cp -f nohup.txt /data/logback/nohup_game3_$(date +%Y%m%d%H%M%S).txt 
rm -rf nohup.txt 
./server.sh start &
else
echo "game3-isruning" | awk '{ print $0"\t" strftime("%Y-%m-%d %H:%M:%S",systime()) }' >> /data/tool/control.txt &
fi
sleep 5s

game4=`ps aux | grep /data/server4/game/p8_app_server | grep -v grep`
if [ "$?" != "0" ];
then
echo "game4-restart" | awk '{ print $0"\t" strftime("%Y-%m-%d %H:%M:%S",systime()) }' >> /data/tool/dump.txt &
cd /data/server4/game/
cp -f nohup.txt /data/logback/nohup_game4_$(date +%Y%m%d%H%M%S).txt 
rm -rf nohup.txt 
./server.sh start &
else
echo "game4-isruning" | awk '{ print $0"\t" strftime("%Y-%m-%d %H:%M:%S",systime()) }' >> /data/tool/control.txt &
fi
sleep 5s

game5=`ps aux | grep /data/server5/game/p8_app_server | grep -v grep`
if [ "$?" != "0" ];
then
echo "game5-restart" | awk '{ print $0"\t" strftime("%Y-%m-%d %H:%M:%S",systime()) }' >> /data/tool/dump.txt &
cd /data/server5/game/
cp -f nohup.txt /data/logback/nohup_game5_$(date +%Y%m%d%H%M%S).txt 
rm -rf nohup.txt 
./server.sh start &
else
echo "game5-isruning" | awk '{ print $0"\t" strftime("%Y-%m-%d %H:%M:%S",systime()) }' >> /data/tool/control.txt &
fi
sleep 5s

gate=`ps aux | grep /data/server/gate/p8_app_server | grep -v grep`
if [ "$?" != "0" ];
then
echo "gate-restart" | awk '{ print $0"\t" strftime("%Y-%m-%d %H:%M:%S",systime()) }' >> /data/tool/dump.txt &
cd /data/server/gate/
cp -f nohup.txt /data/logback/nohup_gate_$(date +%Y%m%d%H%M%S).txt 
rm -rf nohup.txt 
./server.sh start &
else
echo "gate-isruning" | awk '{ print $0"\t" strftime("%Y-%m-%d %H:%M:%S",systime()) }' >> /data/tool/control.txt &
fi
sleep 5s

login=`ps aux | grep /data/server/login/p8_app_server | grep -v grep`
if [ "$?" != "0" ];
then
echo "login-restart" | awk '{ print $0"\t" strftime("%Y-%m-%d %H:%M:%S",systime()) }' >> /data/tool/dump.txt &
cd /data/server/login/
cp -f nohup.txt /data/logback/nohup_login_$(date +%Y%m%d%H%M%S).txt 
rm -rf nohup.txt 
./server.sh start &
else
echo "login-isruning" | awk '{ print $0"\t" strftime("%Y-%m-%d %H:%M:%S",systime()) }' >> /data/tool/control.txt &
fi
sleep 5s
done