#! /bin/bash
# Webcam with raspberry and gphoto2 supported camera

sudo dos2unix /boot/webcam.conf
. /boot/webcam.conf

cd /home/pi/Webcampi/

NOW=`date +%s`
LASTRUNINT=`cat lastrun`
LASTRUN=`date -d "@$LASTRUNINT" +%s`
ET=$((NOW- LASTRUN))
PRESET=$((TIMER * 60))
echo "time elapsed:" $ET
echo "Preset:" $PRESET
if [ $ET -ge $PRESET ]
then
NOW=`date +%s`
LASTRUN=`date +%s`

echo $LASTRUN > lastrun
echo "GetPhoto: Started. " $(date) > Log.txt
rm *jpg

TZone=`date | awk '{ print $6}'`
SUNRISE12H=`curl -s http://weather.yahooapis.com/forecastrss?w=$Location|grep astronomy| awk -F\" '{print $2}'`
SUNRISE24H=`date --date="${SUNRISE12H}" +%T`
DAWN=`date --date "${SUNRISE24H} $2 $TZone -30 min" +%s`

SUNSET12H=`curl -s http://weather.yahooapis.com/forecastrss?w=$Location|grep astronomy| awk -F\" '{print $4}'`
SUNSET24H=`date --date="${SUNSET12H}" +%T`
DUSK=`date --date "${SUNSET24H} $4 $TZone +30 min" +%s`

echo "GetPhoto: Calculate Dusk Dawn and Get Photo. " $(date) >> Log.txt

if [ $NOW -ge $DAWN ] && [ $NOW -le $DUSK ]
then
echo "Parametri Giorno"
echo "GetPhoto: day parameters. " $(date) >> Log.txt
raspistill -w 1600 -h 1200 -co 24 -o $FILETOUPLOAD -sa 40 -sh 100 -ev -5 -ex auto -awb fluorescent  -q 100
fi
if [ $NOW -le $DAWN ] || [ $NOW -ge $DUSK ]
then
echo "Parametri Notte"
echo "GetPhoto: Night parameters. " $(date) >> Log.txt
raspistill -w 1600 -h 1200 -o $FILETOUPLOAD -sa 0 -sh 50 -ISO 400 -ev 50 -awb fluorescent -awbg 1,1 -ss 6000000 -t 60000
fi
echo "GetPhoto: Turned Off Camera. " $(date) >> Log.txt

NOWDT=`date +"%d/%m/%y %R"`

echo $NOWDT

echo "GetPhoto: Imprinting Informations. " $(date) >> Log.txt

convert -verbose -background '#00F8' -fill white -gravity center -size 1600x30 \
          caption:"$DESCRIPTION" \
          $FILETOUPLOAD +swap -gravity south -composite $FILETOUPLOAD

convert -verbose -draw "text 3,1195 'www.torinometeo.org'" -draw "text 1460,1195 '$NOWDT'" \
	-fill yellow -pointsize 20 $FILETOUPLOAD $FILETOUPLOAD

convert $FILETOUPLOAD logoTM2.png -geometry 200x70+1430+1070 -composite -matte $FILETOUPLOAD

echo "GetPhoto: Kill Old FTP Process If Exist And Upload New File" $(date) >> Log.txt
echo "-----" >> Log.txt
echo "System Info:" >> Log.txt
echo "Temperature:" >>Log.txt
echo "Core: " $(/opt/vc/bin/vcgencmd measure_temp) >> Log.txt
echo "Voltages:" >>Log.txt
echo "Core: " $(/opt/vc/bin/vcgencmd measure_volts core) >> Log.txt
echo "SdRam C: " $(/opt/vc/bin/vcgencmd measure_volts sdram_c) >> Log.txt
echo "SdRam I: " $(/opt/vc/bin/vcgencmd measure_volts sdram_i) >> Log.txt
echo "SdRam P: " $(/opt/vc/bin/vcgencmd measure_volts sdram_p) >> Log.txt

ps axf | grep ftp | grep -v grep | awk '{print "kill -9 " $1}' | sh

ftp -dvin $HOSTNAME << EOF
      quote USER $USERNAME
      quote PASS $PASSWORD
      binary
      hash
      cd $DIRECTORY
      put $FILETOUPLOAD
      put Log.txt
quit
EOF
fi
