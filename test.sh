#!/bin/bash


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

