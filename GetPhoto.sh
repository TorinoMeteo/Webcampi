#! /bin/bash
cd /home/pi/webcam/
FILETOUPLOAD=webcam.jpg
    HOSTNAME="ftp.yoursite.com"
    USERNAME="YourUsername"
    PASSWORD="YourPassword"

echo "GetPhoto: Started. " $(date) > Log.txt
sleep 1
gpio -g mode 23 out
gpio -g write 23 1
echo "GetPhoto: Turned On Camera. " $(date) >> Log.txt
sleep 2
gphoto2 --auto-detect
echo "GetPhoto: Loading Drivers. " $(date) >> Log.txt
sleep 1
gphoto2 --set-config capture=on
cd /home/pi/webcam/
rm *jpg
Location=20126313 #this is the yahoo api WOEID for the required location

NOW=`date +%s`

SUNRISE12H=`curl -s http://weather.yahooapis.com/forecastrss?w=$Location|grep astronomy| awk -F\" '{print $2}'`
SUNRISE24H=`date --date="${SUNRISE12H}" +%T`
DAWN=`date --date "${SUNRISE24H} $2 CEST -30 min" +%s`

SUNSET12H=`curl -s http://weather.yahooapis.com/forecastrss?w=$Location|grep astronomy| awk -F\" '{print $4}'`
SUNSET24H=`date --date="${SUNSET12H}" +%T`
DUSK=`date --date "${SUNSET24H} $4 CEST +30 min" +%s`
echo "GetPhoto: Calculate Dusk Dawn and Get Photo. " $(date) >> Log.txt

if [ $NOW -ge $DAWN ] && [ $NOW -le $DUSK ]
then
echo "Parametri Giorno"
echo "GetPhoto: day parameters. " $(date) >> Log.txt
gphoto2 --set-config shootingmode="Auto" --set-config focusingpoint="Multiple Focusing Points (Center)" --set-config capture=on --set-config iso="100" --set-config imagesize="Medium 2" --set-config zoom="0" --filename="IMG.jpg" --capture-image-and-download
fi
if [ $NOW -le $DAWN ] || [ $NOW -ge $DUSK ]
then
echo "Parametri Notte"
echo "GetPhoto: Night parameters. " $(date) >> Log.txt
gphoto2 --set-config shootingmode="Manual" --set-config focusingpoint="Multiple Focusing Points (Center)" --set-config capture=on --set-config iso="100" --set-config imagesize="Medium 2" --set-config zoom="0" --set-config shutterspeed="3" --filename="IMG.jpg" --capture-image-and-download
fi
echo "GetPhoto: Turned Off Camera. " $(date) >> Log.txt
gpio -g write 23 0

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
          caption:"Descrizione Fotografia" \ #aggiungere la propria descrizione
          input2.jpg +swap -gravity north -composite $FILETOUPLOAD

gpio -g write 23 0
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

gpio -g write 23 0

