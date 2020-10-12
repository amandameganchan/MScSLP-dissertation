#!/usr/bin/bash

dir=$1

#while read line; do
#  temp=$(echo $line | cut -d ' ' -f 4-) 
#  echo "${temp} target" >> $dir/all_scores.txt
#done < $dir/targets

#while read linen; do
#  tempn=$(echo $linen | cut -d ' ' -f 4-)         
#  echo "${tempn} nontarget" >> $dir/all_scores.txt
#done < $dir/nontargets

cut -d ' ' -f 1 $dir/all_scores.txt | sort | uniq > $dir/segments.txt
while read lines; do
  grep -F $lines $dir/all_scores.txt | sort -rnk3 | head -1 >> $dir/ids.txt
done < $dir/segments.txt
