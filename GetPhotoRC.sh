#! /bin/bash
# Webcam with raspberry and gphoto2 supported camera

#cd /home/pi/Webcampi/
FILETOUPLOAD=webcam.jpg
HOSTNAME="ftp.yoursite.com"
USERNAME="YourUsername"
PASSWORD="YourPassword"
DESCRIPTION="Descrizione webcam"
Location=20126313 #this is the yahoo api WOEID for the required location



echo "GetPhoto: Started. " $(date) > Log.txt
cd /home/pi/webcam/
rm *jpg

NOW=`date +%s`
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
raspistill -w 1200 -h 1400 -co 24 -o /image.jpg -sa 40 -sh 100 -ev -5 -ex auto -awb fluorescent  -rot 270 -q 100
fi
if [ $NOW -le $DAWN ] || [ $NOW -ge $DUSK ]
then
echo "Parametri Notte"
echo "GetPhoto: Night parameters. " $(date) >> Log.txt
raspistill -w 1200 -h 1400 -rot 270  -o /image.jpg -sa 0 -sh 50 -ISO 400 -ev 50 -awb fluorescent -awbg 1,1 -ss 6000000 -t 60000
fi
echo "GetPhoto: Turned Off Camera. " $(date) >> Log.txt

NOWDT=`date +"%d/%m/%y %R"`

echo $NOWDT

echo "GetPhoto: Imprinting Date And Time. " $(date) >> Log.txt

width=`identify -format %w IMG.jpg`
convert -background '#00F8' -fill white -gravity east -size ${width}x30 \
          caption:"$NOWDT" \
          IMG.jpg +swap -gravity south -composite input2.jpg
echo "GetPhoto: Imprinting Header. " $(date) >> Log.txt
width1=`identify -format %w input2.jpg`
convert -background '#00F8' -fill white -gravity center -size ${width1}x30 \
          caption:$DESCRIPTION
          input2.jpg +swap -gravity north -composite $FILETOUPLOAD

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

    ftp -dvin $HOSTNAME <<EOF
      quote USER $USERNAME
      quote PASS $PASSWORD
      binary
      hash
      cd /remote/folder/to/upload
      put $FILETOUPLOAD
      put Log.txt
quit
EOF
