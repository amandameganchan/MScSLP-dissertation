#!/usr/bin/env bash

# Based on original run.sh script; adapted for baseline suitability
# experiments: trained on 10 hrs of GlobalPhone, then Euronews,
# then combined set, all tested on code-switching data.

# setup
source start.sh

# extract features
# (globalphone 10hrs)
steps/make_mfcc.sh --mfcc-config conf_lre/mfcc.conf --cmd "$train_cmd" \
  data/gp/train_4-5k exp/make_mfcc $mfccdir
lid/compute_vad_decision.sh --cmd "$train_cmd" data/gp/train_4-5k \
  exp/make_vad $vaddir
# (euronews 10hrs)
# >> subset from data/enws/train_4l_8k
steps/make_mfcc.sh --mfcc-config conf_lre/mfcc.conf --cmd "$train_cmd" \
  data/enws/train_4l_8k exp/make_mfcc $mfccdir
lid/compute_vad_decision.sh --cmd "$train_cmd" data/enws/train_4l_8k \
  exp/make_vad $vaddir
utils/subset_data_dir.sh data/enws/train_4l_8k 4000 data/enws/train_4l_4k
# (combined 10hrs)
# >> combine from previous two datasets
utils/subset_data_dir.sh data/gp/train_4-5k 2000 data/gp/train_2k
utils/subset_data_dir.sh data/enws/train_4l_4k 2000 data/enws/train_4l_2k
utils/combine_data.sh data/combined/train_4l_4k data/gp/train_2k data/enws/train_4l_2k
# (switching test set)
# >> features copied from a previous experiment
# data/switching/test_4l

# train diagonal covariance UBM
# (globalphone)
lid/train_diag_ubm.sh --cmd "$train_cmd" data/gp/train_4-5k 2048 \
  exp/gp/train_4-5k/diag_ubm_2048
gmm-global-to-fgmm exp/gp/train_4-5k/diag_ubm_2048/final.dubm \
  exp/gp/train_4-5k/full_ubm_2048/final.ubm
# (euronews)
lid/train_diag_ubm.sh --cmd "$train_cmd" data/enws/train_4l_4k 2048 \
  exp/enws/train_4l_4k/diag_ubm_2048
gmm-global-to-fgmm exp/enws/train_4l_4k/diag_ubm_2048/final.dubm \
  exp/enws/train_4l_4k/full_ubm_2048/final.ubm
# (combined)
lid/train_diag_ubm.sh --cmd "$train_cmd" data/combined/train_4l_4k 2048 \
  exp/combined/train_4l_4k/diag_ubm_2048
gmm-global-to-fgmm exp/combined/train_4l_4k/diag_ubm_2048/final.dubm \
  exp/combined/train_4l_4k/full_ubm_2048/final.ubm

# train i-vector extractor
# (globalphone)
lid/train_ivector_extractor.sh --cmd "$train_cmd --mem 35G" \
  --use-weights true --num-iters 5 exp/gp/train_4-5k/full_ubm_2048/final.ubm \
  data/gp/train_4-5k exp/gp/train_4-5k/extractor_2048
# (euronews)
lid/train_ivector_extractor.sh --cmd "$train_cmd --mem 35G" --nj 5  \
  --use-weights true --num-iters 5 exp/enws/train_4l_4k/full_ubm_2048/final.ubm \
  data/enws/train_4l_4k exp/enws/train_4l_4k/extractor_2048
# (combined)
lid/train_ivector_extractor.sh --cmd "$train_cmd --mem 35G" \
  --use-weights true --num-iters 5 exp/combined/train_4l_4k/full_ubm_2048/final.ubm \
  data/combined/train_4l_4k exp/combined/train_4l_4k/extractor_2048

# extract i-vectors
# (globalphone)
lid/extract_ivectors.sh --cmd "$train_cmd --mem 3G" \
  exp/gp/train_4-5k/extractor_2048 data/gp/train_4-5k_lr \
  exp/gp/train_4-5k/ivectors_train
lid/extract_ivectors.sh --cmd "$train_cmd --mem 3G" --nj 10 \
  exp/gp/train_4-5k/extractor_2048 data/switching/test_4l \
  exp/gp/train_4-5k/ivectors_switching_test
# (euronews)
lid/extract_ivectors.sh --cmd "$train_cmd --mem 3G" \
  exp/enws/train_4l_4k/extractor_2048 data/enws/train_4l_4k_lr \
  exp/enws/train_4l_4k/ivectors_train
lid/extract_ivectors.sh --cmd "$train_cmd --mem 3G" --nj 10 \
  exp/enws/train_4l_4k/extractor_2048 data/switching/test_4l \
  exp/enws/train_4l_4k/ivectors_switching_test
# (combined)
lid/extract_ivectors.sh --cmd "$train_cmd --mem 3G" \
  exp/combined/train_4l_4k/extractor_2048 data/combined/train_4l_4k_lr \
  exp/combined/train_4l_4k/ivectors_train
lid/extract_ivectors.sh --cmd "$train_cmd --mem 3G" --nj 10 \
  exp/combined/train_4l_4k/extractor_2048 data/switching/test_4l \
  exp/combined/train_4l_4k/ivectors_switching_test

# train logistic regression model
# (globalphone)
lid/run_logistic_regression.sh exp/gp/train_4-5k/ivectors_train \
  exp/gp/train_4-5k/ivectors_switching_test data/gp/train_4-5k_lr \
  data/switching/test_4l > results/gp10hr_lr.txt
# (euronews)
lid/run_logistic_regression.sh exp/enws/train_4l_4k/ivectors_train \
  exp/enws/train_4l_4k/ivectors_switching_test data/enws/train_4l_4k_lr \
  data/switching/test_4l > results/enws10hr_lr.txt
# (combined)
lid/run_logistic_regression.sh exp/combined/train_4l_4k/ivectors_train \
  exp/combined/train_4l_4k/ivectors_switching_test data/combined/train_4l_4k_lr \
  data/switching/test_4l > results/combined10hr_lr.txt

# evaluate on test set
# (globalphone)
local/gen_eval/eval.sh data/switching/test_4l \
  exp/gp/train_4-5k/ivectors_switching_test local/general_lr_closed_set_langs.txt \
  "gp10hr" > results/gp10hr_eval.txt
local/gen_eval/run-eer.sh local/gen_eval/gp10hr-results
# (euronews)
local/gen_eval/eval.sh data/switching/test_4l \
  exp/enws/train_4l_4k/ivectors_switching_test local/general_lr_closed_set_langs.txt \
  "enws10hr" > results/enws10hr_eval.txt
local/gen_eval/run-eer.sh local/gen_eval/enws10hr-results
# (combined)
local/gen_eval/eval.sh data/switching/test_4l \
  exp/combined/train_4l_4k/ivectors_switching_test \
  local/general_lr_closed_set_langs.txt "combined10hr" > results/combined10hr_eval.txt
local/gen_eval/run-eer.sh local/gen_eval/combined10hr-results
