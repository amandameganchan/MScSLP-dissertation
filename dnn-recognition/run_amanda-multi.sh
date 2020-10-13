#!/usr/bin/env bash

# Based on original run.sh script; adapted for multilingually-trained 
# (EN/FR/GE/PL/ES 50hrs) DNN-UBM experiment. I-vector extractor and
# logistic regression trained on combined Euronews/GlobalPhone 50hrs
# train set (same as in GMM-UBM baseline exp). Tested on code-switching
# data (switching) and Euronews control test set (sanitycheck).

# setup
source start.sh

# train multilingual DNN
local/dnn/train_dnn_multi.sh

# make dnn version folders of the data -- *already done in mono exp*
#cp -r data/combined data/combined_dnn
#cp -r data/switching_5l data/switching_5l_dnn
#cp -r data/test-sanitycheck data/test-sanitycheck_dnn

# extract features -- *already done in mono exp*
#steps/make_mfcc.sh --mfcc-config conf/mfcc.conf --cmd "$train_cmd" \
#  data/combined exp/make_mfcc $mfccdir/combined
#steps/make_mfcc.sh --mfcc-config conf/mfcc.conf --cmd "$train_cmd" \
#  data/switching_5l exp/make_mfcc $mfccdir/switching
#steps/make_mfcc.sh --mfcc-config conf/mfcc.conf --cmd "$train_cmd" \
#  data/test-sanitycheck exp/make_mfcc $mfccdir/sanitycheck

# extract DNN features (hires for use with DNN) -- *already done in mono exp*
#steps/make_mfcc.sh --mfcc-config conf/mfcc_hires.conf --cmd "$train_cmd" \
#  data/combined_dnn exp/make_mfcc $mfccdir/combined
#steps/make_mfcc.sh --mfcc-config conf/mfcc_hires.conf --cmd "$train_cmd" \
#  data/switching_5l_dnn exp/make_mfcc $mfccdir/switching
#steps/make_mfcc.sh --mfcc-config conf/mfcc_hires.conf --cmd "$train_cmd" \
#  data/test-sanitycheck_dnn exp/make_mfcc $mfccdir/sanitycheck

# fix data dirs -- *already done in mono exp*
#for name in combined combined_dnn switching_5l switching_5l_dnn test-sanitycheck test-sanitycheck_dnn; do
#  utils/fix_data_dir.sh data/${name}
#done

# compute vad -- *already done in mono exp*
#lid/compute_vad_decision.sh --cmd "$train_cmd" data/combined \
#  exp/make_vad $vaddir/combined
#lid/compute_vad_decision.sh --cmd "$train_cmd" data/switching_5l \
#  exp/make_vad $vaddir/switching
#lid/compute_vad_decision.sh --cmd "$train_cmd" data/test-sanitycheck \
#  exp/make_vad $vaddir/sanitycheck

# copy files to dnn folders -- *already done in mono exp*
#for name in combined switching_5l test-sanitycheck; do
#  cp data/${name}/vad.scp data/${name}_dnn/vad.scp
#  cp data/${name}/utt2spk data/${name}_dnn/utt2spk
#  cp data/${name}/spk2utt data/${name}_dnn/spk2utt
#  utils/fix_data_dir.sh data/${name}
#  utils/fix_data_dir.sh data/${name}_dnn
#done

# initialize a full GMM from the DNN posteriors and training (combined folder) audio features
lid/init_full_ubm_from_dnn.sh --cmd "$train_cmd --mem 6G" data/combined \
  data/combined_dnn $nnet_multi exp/dnn_multi/full_ubm

# train i-vector extractor based on the DNN-UBM
lid/train_ivector_extractor_dnn.sh --cmd "$train_cmd --mem 80G" \
  --nnet-job-opt "--mem 4G" --min-post 0.015 --ivector-dim 600 \
  --num-iters 5 --nj 4 exp/dnn_multi/full_ubm/final.ubm $nnet_multi \
  data/combined data/combined_dnn exp/dnn_multi/extractor_dnn

# make copy of training data for logistic regression training -- *already done in mono exp*
#cp -r data/combined data/combined_lr
#cp -r data/combined_dnn data/combined_lr_dnn

# extract i-vectors
lid/extract_ivectors_dnn.sh --cmd "$train_cmd --mem 30G" --nj 4 \
  exp/dnn_multi/extractor_dnn $nnet_multi data/combined_lr \
  data/combined_lr_dnn exp/dnn_multi/ivectors_train

lid/extract_ivectors_dnn.sh --cmd "$train_cmd --mem 30G" --nj 4 \
  exp/dnn_multi/extractor_dnn $nnet_multi data/switching_5l \
  data/switching_5l_dnn exp/dnn_multi/ivectors_switching

lid/extract_ivectors_dnn.sh --cmd "$train_cmd --mem 30G" --nj 4 \
  exp/dnn_multi/extractor_dnn $nnet_multi data/test-sanitycheck \
  data/test-sanitycheck_dnn exp/sanitycheck/ivectors_multi

# train logistic regression model
lid/run_logistic_regression.sh exp/dnn_multi/ivectors_train \
  exp/dnn_multi/ivectors_switching data/combined_lr \
  data/switching_5l > results/dnn_multi_lr.txt

lid/run_logistic_regression.sh exp/dnn_multi/ivectors_train \
  exp/sanitycheck/ivectors_multi data/combined_lr \
  data/test-sanitycheck > results/sanitycheck_multi_lr.txt

# evaluate on test set
local/gen_eval/eval.sh data/switching_5l exp/dnn_multi/ivectors_switching \
  local/general_lr_closed_set_langs.txt "dnn-multi" > results/dnn_multi_eval.txt
local/gen_eval/run-eer.sh local/gen_eval/dnn-multi-results

local/gen_eval/eval.sh data/test-sanitycheck exp/sanitycheck/ivectors_multi \
  local/general_lr_closed_set_langs.txt "sanitycheck-multi" > results/sanitycheck_multi_eval.txt
local/gen_eval/run-eer.sh local/gen_eval/sanitycheck-multi-results
