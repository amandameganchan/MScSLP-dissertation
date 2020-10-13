#!/usr/bin/bash

# takes a results directory (with targets and non-targets files) and computes the EER
dir=$1

cut -d ' ' -f 6 $dir/targets > $dir/tgts
while read line; do
  echo "${line} target" >> $dir/scores
done < $dir/tgts
rm $dir/tgts

cut -d ' ' -f 6 $dir/nontargets > $dir/ntgts
while read line; do
  echo "${line} nontarget" >> $dir/scores
done < $dir/ntgts
rm $dir/ntgts

compute-eer $dir/scores >> $dir/eer-score 2>&1
