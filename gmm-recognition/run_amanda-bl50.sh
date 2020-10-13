#!/usr/bin/env bash

# Based on original run.sh script; adapted for baseline 50hr
# experiments: trained on 50 hrs of Euronews, then 50hrs
# combined set, both tested on code-switching data. Combined 
# tested on euronews control test set as well.

# setup
source start.sh

# extract features
# (euronews 50hrs)
steps/make_mfcc.sh --mfcc-config conf_lre/mfcc.conf --cmd "$train_cmd" \
  data/enws/train_5l_50hr exp/make_mfcc $mfccdir
lid/compute_vad_decision.sh --cmd "$train_cmd" data/enws/train_5l_50hr \
  exp/make_vad $vaddir
# (combined 50hrs)
steps/make_mfcc.sh --mfcc-config conf_lre/mfcc.conf --cmd "$train_cmd" \
  data/combined/train_5l_50hr_comb exp/make_mfcc $mfccdir
lid/compute_vad_decision.sh --cmd "$train_cmd" \
  data/combined/train_5l_50hr_comb exp/make_vad $vaddir
# (switching test set)
# >> same as in 10hr experiments
# data/switching/test_4l 
# (euronews control test set)
# >> combined small bits of every language (unused in train set) to copy 
#    language composition of switching test set
# data/enws/test-sanitycheck

# train diagonal covariance UBM
# (euronews) 
lid/train_diag_ubm.sh --cmd "$train_cmd" data/enws/train_5l_50hr \
  2048 exp/enws/train_5l_50hr/diag_ubm_2048
gmm-global-to-fgmm exp/enws/train_5l_50hr/diag_ubm_2048/final.dubm \
  exp/enws/train_5l_50hr/full_ubm_2048/final.ubm
# (combined)
lid/train_diag_ubm.sh --cmd "$train_cmd" data/combined/train_5l_50hr_comb \
  2048 exp/combined/train_5l_50hr/diag_ubm_2048
gmm-global-to-fgmm exp/combined/train_5l_50hr/diag_ubm_2048/final.dubm \
  exp/combined/train_5l_50hr/full_ubm_2048/final.ubm

# train i-vector extractor
# (euronews)
lid/train_ivector_extractor.sh --cmd "$train_cmd --mem 35G" --nj 5 \
  --use-weights true --num-iters 5 exp/enws/train_5l_50hr/full_ubm_2048/final.ubm \
  data/enws/train_5l_50hr exp/enws/train_5l_50hr/extractor_2048
# (combined)
lid/train_ivector_extractor.sh --cmd "$train_cmd --mem 35G" --nj 5 \
  --use-weights true --num-iters 5 exp/combined/train_5l_50hr/full_ubm_2048/final.ubm \
  data/combined/train_5l_50hr_comb exp/combined/train_5l_50hr/extractor_2048

# extract i-vectors
# (euronews) 
lid/extract_ivectors.sh --cmd "$train_cmd --mem 3G" \
  exp/enws/train_5l_50hr/extractor_2048 data/enws/train_5l_50hr_lr \
  exp/enws/train_5l_50hr/ivectors_train
lid/extract_ivectors.sh --cmd "$train_cmd --mem 3G" --nj 10 \
  exp/enws/train_5l_50hr/extractor_2048 data/switching/test_5l \
  exp/enws/train_5l_50hr/ivectors_switching_test
# (combined)
lid/extract_ivectors.sh --cmd "$train_cmd --mem 3G" \
  exp/combined/train_5l_50hr/extractor_2048 data/combined/train_5l_50hr_lr \
  exp/combined/train_5l_50hr/ivectors_train
lid/extract_ivectors.sh --cmd "$train_cmd --mem 3G" --nj 10 \
  exp/combined/train_5l_50hr/extractor_2048 data/switching/test_5l \
  exp/combined/train_5l_50hr/ivectors_switching_test
lid/extract_ivectors.sh --cmd "$train_cmd --mem 3G" \
  exp/combined/train_5l_50hr/extractor_2048 data/enws/test-sanitycheck \
  exp/combined/train_5l_50hr/ivectors_enwstest

# train logistic regression model
# (euronews)
lid/run_logistic_regression.sh exp/enws/train_5l_50hr/ivectors_train \
  exp/enws/train_5l_50hr/ivectors_switching_test data/enws/train_5l_50hr_lr \
  data/switching/test_5l > results/enws50hr_lr.txt
# (combined) 
lid/run_logistic_regression.sh exp/combined/train_5l_50hr/ivectors_train \
  exp/combined/train_5l_50hr/ivectors_switching_test data/combined/train_5l_50hr_lr \
  data/switching/test_5l > results/combined50hr_lr.txt
lid/run_logistic_regression.sh exp/combined/train_5l_50hr/ivectors_train \
  exp/combined/train_5l_50hr/ivectors_enwstest data/combined/train_5l_50hr_lr \
  data/enws/test-sanitycheck > results/sanitycheck_lr.txt

# evaluate on test set
# (euronews) 
local/gen_eval/eval.sh data/switching/test_5l exp/enws/train_5l_50hr/ivectors_switching_test \
  local/general_lr_closed_set_langs.txt "enws50hr" > results/enws50hr_eval.txt
local/gen_eval/run-eer.sh local/gen_eval/enws50hr-results
# (combined)
# >> switching test set
local/gen_eval/eval.sh data/switching/test_5l exp/combined/train_5l_50hr/ivectors_switching_test \
  local/general_lr_closed_set_langs.txt "combined50hr" > results/combined50hr_eval.txt
local/gen_eval/run-eer.sh local/gen_eval/combined50hr-results
# >> control test set
local/gen_eval/eval.sh data/enws/test-sanitycheck exp/combined/train_5l_50hr/ivectors_enwstest \
  local/general_lr_closed_set_langs.txt "sanitycheck" > results/sanitycheck_eval.txt
local/gen_eval/run-eer.sh local/gen_eval/sanitycheck-results
