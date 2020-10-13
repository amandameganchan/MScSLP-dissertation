#!/usr/bin/bash

# Calculate total duration of segments/durs listed in utt2dur file

if [ $# != 1 ]; then
  echo "Usage: total_duration_utt2dur.sh <utt2dur>"
  exit 1;
fi 

# read in utt2dur file
durs=$1

tot_hr=0
tot_min=0
tot_sec=0
tot_msec=0

counter=0
tot_audios=$(wc -l $durs | cut -d ' ' -f 1)

# for each line in file:
while read line || [[ -n $line ]]; do

  counter=$(($counter+1)) 
  echo -ne "$counter/$tot_audios \r"

  duration=$(echo $line | cut -d ' ' -f 2 | xargs)  
  duration="${duration}.0"

  sec=$(echo $duration | cut -d '.' -f 1 | xargs)
  tot_sec=$((10#$tot_sec+10#$sec))
  msec=$(echo $duration | cut -d '.' -f 2 | xargs)
  if [[ ${msec:0:1} -gt 4 ]]; then
    msec=1000
  else
    msec=0
  fi
  tot_msec=$((10#$tot_msec+10#$msec))

done <$durs

msec_sec=$((10#$tot_msec/1000))
tot_msec=$((10#$tot_msec%1000))
tot_sec=$((10#$tot_sec+10#$msec_sec))

avg_dur=$((10#$tot_sec/10#$tot_audios)) 

sec_min=$((10#$tot_sec/60))
tot_sec=$((10#$tot_sec%60))
tot_min=$((10#$tot_min+10#$sec_min))

min_hr=$((10#$tot_min/60))
tot_min=$((10#$tot_min%60))
tot_hr=$((10#$tot_hr+10#$min_hr))

echo "total duration of audio files in $durs: $tot_hr:$tot_min:$tot_sec.$tot_msec"
echo "average duration of segment: $avg_dur seconds"
