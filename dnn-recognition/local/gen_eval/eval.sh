#!/usr/bin/env bash
# Copyright  2014   David Snyder
# Apache 2.0.
#
# Calculates the 3s, 10s, and 30s error rates and C_avgs on the LRE07 
# General Language Recognition closed-set using the directory containing 
# the language identification posteriors.  Detailed results such as the 
# probability of misses for individual languages are computed in 
# local/lre07_eval/lre07_results.
#
# July/5/2020: adapted script to more general data -- only calculate 
# averages (not divided out by length) and give paths as args instead
# of hard-coded [Amanda C.] 

. ./cmd.sh
. ./path.sh
set -e

if [ $# != 4 ]; then
  echo "Usage: eval.sh <test-data-dir> <test-ivectors-dir> <lang-file> <experiment-name>"
  exit 1;
fi

test_data_dir=$1
posterior_dir=$2
languages_file=$3
experiment=$4

mkdir -p local/gen_eval/$experiment-results
results_dir=local/gen_eval/$experiment-results

local/gen_eval/targets.pl $posterior_dir/posteriors $test_data_dir/utt2lang \
  $languages_file $results_dir/targets \
  $results_dir/nontargets>/dev/null

# Create the the score (eg, targets.scr) file.
local/gen_eval/score.v01d.pl -t $results_dir/targets -n $results_dir/nontargets

# Compute the posterior probabilities for each duration, as well as
# the target and nontarget files.
#for dur in "3" "10" "30"; do
  #utils/filter_scp.pl -f 1 data/lre07/"$dur"sec \
    #$posterior_dir/posteriors > \
    #$posterior_dir/posteriors_"$dur"sec
  #local/lre07_eval/lre07_targets.pl $posterior_dir/posteriors_"$dur"sec \
    #<(utils/filter_scp.pl -f 1 data/lre07/"$dur"sec data/lre07/utt2lang) \
    #$languages_file \
    #"$lre07_dir"/targets_"$dur"sec "$lre07_dir"/nontargets_"$dur"sec>/dev/null
  #local/lre07_eval/score_lre07.v01d.pl -t "$lre07_dir"/targets_"$dur"sec -n \
    #"$lre07_dir"/nontargets_"$dur"sec>/dev/null
#done

#printf '% 15s' 'Duration (sec):'
#for dur in "avg" "3" "10" "30"; do
  #printf '% 7s' $dur;
#done
#echo

printf '% 10s' 'ER (%):'

# Get the overall classification and then individual duration error rates.
er=$(compute-wer --text ark:<(lid/remove_dialect.pl $test_data_dir/utt2lang) \
  ark:$posterior_dir/output 2>/dev/null | grep "WER" | awk '{print $2 }')
printf '% 7.2f' $er

#for dur in "3" "10" "30"; do
  #er=$(compute-wer --text ark:<(utils/filter_scp.pl -f 1 \
    #data/lre07/"$dur"sec data/lre07/utt2lang | lid/remove_dialect.pl -) \
    #ark:<(utils/filter_scp.pl -f 1 data/lre07/"$dur"sec \
      #$posterior_dir/output) \
    #2>/dev/null | grep "WER" | awk '{print $2 }')
    #printf '% 7.2f' $er
#done
echo

printf '% 10s' 'C_avg (%):'

# Get the overall C_avg and then C_avgs for the individual durations.
cavg=$(tail -n 1 $results_dir/targets.scr \
     | awk '{print 100*$4 }')
printf '% 7.2f' $cavg

#for dur in "3" "10" "30"; do
  #cavg=$(tail -n 1 $lre07_dir/targets_${dur}sec.scr \
       #| awk '{print 100.0*$4 }')
  #printf '% 7.2f' $cavg
#done
echo
