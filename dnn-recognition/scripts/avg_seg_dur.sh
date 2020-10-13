#!/usr/bin/bash

# takes segments file as input and computes average segment length in seconds as well as total time in hh:mm
file=$1

line_n=0
tot_lines=$(wc -l $file | cut -d ' ' -f 1 | xargs)

total=0

while read line || [[ -n $line ]]; do
    
    line_n=$(($line_n+1))
    echo -ne "$line_n/$tot_lines \r"
    
    start_time=$(( 10#$(echo $line | cut -d ' ' -f 3 | cut -d '.' -f 1) * 1000))
    start_time=$(( 10#$start_time + 10#$(echo $line | cut -d ' ' -f 3 | cut -d '.' -f 2) ))
    end_time=$(( 10#$(echo $line | cut -d ' ' -f 4 | cut -d '.' -f 1) * 1000)) 
    end_time=$(( 10#$end_time + 10#$(echo $line | cut -d ' ' -f 4 | cut -d '.' -f 2) ))

    add_time=$((10#$end_time - 10#$start_time))
    total=$((10#$total + 10#$add_time))
    
done <$file

total_sec=$((10#$total / 1000))
avg=$((10#$total_sec / 10#$line_n))
total_min=$((10#$total_sec / 60))
total_hr=$((10#$total_min / 60))
total_min=$((10#$total_min % 60))

echo "average segment length: $avg s"
echo "total time: $total_hr:$total_min"
