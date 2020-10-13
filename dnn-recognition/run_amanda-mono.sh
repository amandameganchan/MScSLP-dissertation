#!/usr/bin/env bash

# Based on original run.sh script; adapted for monolingually-trained 
# (Euronews English 50hrs) DNN-UBM experiment. I-vector extractor and
# logistic regression trained on combined Euronews/GlobalPhone 50hrs
# train set (same as in GMM-UBM baseline exp). Tested on code-switching
# data (switching) and Euronews control test set (sanitycheck).

# setup
source start.sh

# train mono DNN
local/dnn/train_dnn_mono.sh

# make dnn version folders of the data
cp -r data/combined data/combined_dnn
cp -r data/switching_5l data/switching_5l_dnn
cp -r data/test-sanitycheck data/test-sanitycheck_dnn

# extract features
steps/make_mfcc.sh --mfcc-config conf/mfcc.conf --cmd "$train_cmd" \
  data/combined exp/make_mfcc $mfccdir/combined

steps/make_mfcc.sh --mfcc-config conf/mfcc.conf --cmd "$train_cmd" \
  data/switching_5l exp/make_mfcc $mfccdir/switching

steps/make_mfcc.sh --mfcc-config conf/mfcc.conf --cmd "$train_cmd" \
  data/test-sanitycheck exp/make_mfcc $mfccdir/sanitycheck

# extract DNN features (hires for use with DNN)
steps/make_mfcc.sh --mfcc-config conf/mfcc_hires.conf --cmd "$train_cmd" \
  data/combined_dnn exp/make_mfcc $mfccdir/combined

steps/make_mfcc.sh --mfcc-config conf/mfcc_hires.conf --cmd "$train_cmd" \
  data/switching_5l_dnn exp/make_mfcc $mfccdir/switching

steps/make_mfcc.sh --mfcc-config conf/mfcc_hires.conf --cmd "$train_cmd" \
  data/test-sanitycheck_dnn exp/make_mfcc $mfccdir/sanitycheck

# fix data dirs
for name in combined combined_dnn switching_5l switching_5l_dnn test-sanitycheck test-sanitycheck_dnn; do
  utils/fix_data_dir.sh data/${name}
done

# compute vad
lid/compute_vad_decision.sh --cmd "$train_cmd" data/combined \
  exp/make_vad $vaddir/combined
lid/compute_vad_decision.sh --cmd "$train_cmd" data/switching_5l \
  exp/make_vad $vaddir/switching
lid/compute_vad_decision.sh --cmd "$train_cmd" data/test-sanitycheck \
  exp/make_vad $vaddir/sanitycheck

# copy files to dnn folders
for name in combined switching_5l test-sanitycheck; do
  cp data/${name}/vad.scp data/${name}_dnn/vad.scp
  cp data/${name}/utt2spk data/${name}_dnn/utt2spk
  cp data/${name}/spk2utt data/${name}_dnn/spk2utt
  utils/fix_data_dir.sh data/${name}
  utils/fix_data_dir.sh data/${name}_dnn
done

# initialize a full GMM from the DNN posteriors and training (combined folder) audio features
lid/init_full_ubm_from_dnn.sh --cmd "$train_cmd --mem 6G" data/combined \
  data/combined_dnn $nnet_mono exp/full_ubm

# train i-vector extractor based on the DNN-UBM
lid/train_ivector_extractor_dnn.sh --cmd "$train_cmd --mem 80G" \ 
  --nnet-job-opt "--mem 4G" --min-post 0.015 --ivector-dim 600 \
  --num-iters 5 --nj 4 exp/full_ubm/final.ubm $nnet_mono \
  data/combined data/combined_dnn exp/enws_mono/extractor_dnn

# make copy of training data for logistic regression training
cp -r data/combined data/combined_lr
cp -r data/combined_dnn data/combined_lr_dnn

# extract i-vectors
lid/extract_ivectors_dnn.sh --cmd "$train_cmd --mem 30G" --nj 4 \
  exp/enws_mono/extractor_dnn $nnet_mono data/combined_lr \
  data/combined_lr_dnn exp/enws_mono_fix/ivectors_train

lid/extract_ivectors_dnn.sh --cmd "$train_cmd --mem 30G" --nj 4 \
  exp/enws_mono/extractor_dnn $nnet_mono data/switching_5l \
  data/switching_5l_dnn exp/enws_mono_fix/ivectors_switching

lid/extract_ivectors_dnn.sh --cmd "$train_cmd --mem 30G" --nj 4 \
  exp/enws_mono/extractor_dnn $nnet_mono data/test-sanitycheck \
  data/test-sanitycheck_dnn exp/sanitycheck/ivectors_mono

# train logistic regression model
lid/run_logistic_regression.sh exp/enws_mono_fix/ivectors_train \
  exp/enws_mono_fix/ivectors_switching data/combined_lr \
  data/switching_5l > results/dnn_mono_lr.txt

lid/run_logistic_regression.sh exp/enws_mono_fix/ivectors_train \
  exp/sanitycheck/ivectors_mono data/combined_lr \
  data/test-sanitycheck > results/sanitycheck_mono_lr.txt

# evaluate on test set
local/gen_eval/eval.sh data/switching_5l exp/enws_mono_fix/ivectors_switching \
  local/general_lr_closed_set_langs.txt "dnn-mono" > results/dnn_mono_eval.txt
local/gen_eval/run-eer.sh local/gen_eval/dnn-mono-results

local/gen_eval/eval.sh data/test-sanitycheck exp/sanitycheck/ivectors_mono \
  local/general_lr_closed_set_langs.txt "sanitycheck-mono" > results/sanitycheck_mono_eval.txt
local/gen_eval/run-eer.sh local/gen_eval/sanitycheck-mono-results
