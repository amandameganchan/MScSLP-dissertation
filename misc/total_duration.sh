#!/usr/bin/bash

# Calculate total duration of audio files listed in wav.scp file
# using soxi duration

if [ $# != 1 ]; then
  echo "Usage: total_duration.sh <wav.scp file>"
  exit 1;
fi 

# read in wav.scp file
wavs=$1

tot_hr=0
tot_min=0
tot_sec=0
tot_msec=0

counter=0
tot_audios=$(wc -l $wavs | cut -d ' ' -f 1)

# for each line in file:
while read line || [[ -n $line ]]; do

  counter=$(($counter+1)) 
  echo -ne "$counter/$tot_audios \r"

  audio=$(echo $line | cut -d ' ' -f 2 | xargs)
  dur=$(soxi $audio | grep "Duration" | grep -o "..:..:..\...") 
  hr=$(echo $dur | cut -d ':' -f 1 | xargs)
  tot_hr=$((10#$tot_hr+10#$hr))
  min=$(echo $dur | cut -d ':' -f 2 | xargs)
  tot_min=$((10#$tot_min+10#$min))
  sec=$(echo $dur | cut -d ':' -f 3 | cut -d '.' -f 1 | xargs)
  tot_sec=$((10#$tot_sec+10#$sec))
  msec=$(echo $dur | cut -d ':' -f 3 | cut -d '.' -f 2 | xargs)
  tot_msec=$((10#$tot_msec+10#$msec)) 

done <$wavs

msec_sec=$((10#$tot_msec/1000))
tot_msec=$((10#$tot_msec%1000))
tot_sec=$((10#$tot_sec+10#$msec_sec))

sec_min=$((10#$tot_sec/60))
tot_sec=$((10#$tot_sec-10#$sec_min*60))
tot_min=$((10#$tot_min+10#$sec_min))

min_hr=$((10#$tot_min/60))
tot_min=$((10#$tot_min-10#$min_hr*60))
tot_hr=$((10#$tot_hr+10#$min_hr))

echo "total duration of audio files in $wavs: $tot_hr:$tot_min:$tot_sec.$tot_msec"
