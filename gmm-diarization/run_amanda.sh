#!/usr/bin/env bash

# Based on original run.sh script; adapted for use with languages instead
# of speakers. UBM and i-vector extractor taken from recognition experiment 
# (in final_tests folder). Tested on code-switching data, by language 
# clusters and then speaker-language clusters, and with both auto and oracle VAD.

# setup
source start.sh

# data copied from recognition experiment
# ensure spk2utt/utt2spk files contain 'recID uttID'/'uttID recID'
#   --> train set: data/train_5l_50hr_original
#   --> test set: data/test_5l 

# split test set into 2 subsets [for whitening purposes]
# (split in half- first 3 couples, last 3 couples)
#   --> data/test_subset_1 and data/test_subset_2

# do auto VAD segmentation 
# (use mfcc/edit_vad.sh to convert non-speech noise in vad files into speech 
# noise in order to use diarization/vad_to_segments.sh to create segments)
#   --> data/test_subset_1_segmented and data/test_subset_2_segmented 

# keep oracle VAD segmentation
#   --> data/new_test1 and data/new_test2

# UBM/i-vector extractor copied from recognition experiment
#   --> exp/extractor_2048

# extract i-vectors
diarization/extract_ivectors.sh --cmd "$train_cmd --mem 25G" --window 3.0 \
  --period 10.0 --min-segment 1.5 --hard-min true exp/extractor_2048 \
  data/train_5l_50hr_original exp/ivectors_train

diarization/extract_ivectors.sh --nj 10 --cmd "$train_cmd --mem 20G" \
  --window 1.5 --period 0.75 --min-segment 0.5 exp/extractor_2048 \
  data/test_subset_1_segmented exp/ivectors_test_1

diarization/extract_ivectors.sh --nj 5 --cmd "$train_cmd --mem 20G" \
  --window 1.5 --period 0.75 --min-segment 0.5 exp/extractor_2048 \
  data/test_subset_2_segmented exp/ivectors_test_2

diarization/extract_ivectors.sh --nj 10 --cmd "$train_cmd --mem 20G" \
  --window 1.5 --period 0.75 --min-segment 0.5 exp/extractor_2048 \
  data/new_test1 exp/ivectors_test_1_cheat

diarization/extract_ivectors.sh --nj 9 --cmd "$train_cmd --mem 20G" \
  --window 1.5 --period 0.75 --min-segment 0.5 exp/extractor_2048 \
  data/new_test2 exp/ivectors_test_2_cheat

# train PLDA models
# ensure spk2utt/utt2spk files contain 'langID uttID'/'uttID langID'
# ***auto VAD***:
# >> train a PLDA model on combined train set, using test subset 1 to whiten
#    for later use in scoring test subset 2 i-vectors
"$train_cmd" exp/ivectors_test_1/log/plda.log \
    ivector-compute-plda ark:exp/ivectors_train/spk2utt \
      "ark:ivector-subtract-global-mean \
      scp:exp/ivectors_train/ivector.scp ark:- \
      | transform-vec exp/ivectors_test_1/transform.mat ark:- ark:- \
      | ivector-normalize-length ark:- ark:- |" \
    exp/ivectors_test_1/plda
# >> train a PLDA model on combined train set, using test subset 2 to whiten
#    for later use in scoring test subset 1 i-vectors
"$train_cmd" exp/ivectors_test_2/log/plda.log \
    ivector-compute-plda ark:exp/ivectors_train/spk2utt \
      "ark:ivector-subtract-global-mean \
      scp:exp/ivectors_train/ivector.scp ark:- \
      | transform-vec exp/ivectors_test_2/transform.mat ark:- ark:- \
      | ivector-normalize-length ark:- ark:- |" \
    exp/ivectors_test_2/plda
# ***oracle VAD***:
# >> train a PLDA model on combined train set, using test subset 1 to whiten
#    for later use in scoring test subset 2 i-vectors
"$train_cmd" exp/ivectors_test_1_cheat/log/plda.log \
    ivector-compute-plda ark:exp/ivectors_train/spk2utt \
      "ark:ivector-subtract-global-mean \
      scp:exp/ivectors_train/ivector.scp ark:- \
      | transform-vec exp/ivectors_test_1_cheat/transform.mat ark:- ark:- \
      | ivector-normalize-length ark:- ark:- |" \
    exp/ivectors_test_1_cheat/plda
# >> train a PLDA model on combined train set, using test subset 2 to whiten
#    for later use in scoring test subset 1 i-vectors
"$train_cmd" exp/ivectors_test_2_cheat/log/plda.log \
    ivector-compute-plda ark:exp/ivectors_train/spk2utt \
      "ark:ivector-subtract-global-mean \
      scp:exp/ivectors_train/ivector.scp ark:- \
      | transform-vec exp/ivectors_test_2_cheat/transform.mat ark:- ark:- \
      | ivector-normalize-length ark:- ark:- |" \
    exp/ivectors_test_2_cheat/plda

# perform PLDA scoring on all pairs of segments for each recording
# ***auto VAD***:
diarization/score_plda.sh --cmd "$train_cmd --mem 4G" exp/ivectors_test_2 \
  exp/ivectors_test_1 exp/ivectors_test_1/plda_scores
diarization/score_plda.sh --cmd "$train_cmd --mem 4G" --nj 9 \
  exp/ivectors_test_1 exp/ivectors_test_2 exp/ivectors_test_2/plda_scores
# ***oracle VAD***:
diarization/score_plda.sh --cmd "$train_cmd --mem 4G" exp/ivectors_test_2_cheat \
  exp/ivectors_test_1_cheat exp/ivectors_test_1_cheat/plda_scores
diarization/score_plda.sh --cmd "$train_cmd --mem 4G" --nj 9 \
  exp/ivectors_test_1_cheat exp/ivectors_test_2_cheat \
  exp/ivectors_test_2_cheat/plda_scores

# cluster PLDA scores using oracle number of languages
# ***auto VAD***:
diarization/cluster.sh --cmd "$train_cmd --mem 4G" \
  --reco2num-spk data/test_subset_1_segmented/reco2num_spk \
  exp/ivectors_test_1/plda_scores exp/ivectors_test_1/plda_scores_num_spk
diarization/cluster.sh --cmd "$train_cmd --mem 4G" --nj 9 \
  --reco2num-spk data/test_subset_2_segmented/reco2num_spk \
  exp/ivectors_test_2/plda_scores exp/ivectors_test_2/plda_scores_num_spk
# ***oracle VAD***:
diarization/cluster.sh --cmd "$train_cmd --mem 4G" \
  --reco2num-spk data/test_subset_1_segmented/reco2num_spk \
  exp/ivectors_test_1_cheat/plda_scores exp/ivectors_test_1_cheat/plda_scores_num_spk
diarization/cluster.sh --cmd "$train_cmd --mem 4G" --nj 9 \
  --reco2num-spk data/test_subset_2_segmented/reco2num_spk \
  exp/ivectors_test_2_cheat/plda_scores exp/ivectors_test_2_cheat/plda_scores_num_spk

# cluster PLDA scores using oracle number of speaker-language pairs
# ***auto VAD***:
diarization/cluster.sh --cmd "$train_cmd --mem 4G" \
  --reco2num-spk results/results_spk-lang/reco2num_spk exp/ivectors_test_1/plda_scores \
  exp/ivectors_test_1/plda_scores_num_spk-lang
diarization/cluster.sh --cmd "$train_cmd --mem 4G" --nj 9 \
  --reco2num-spk results/results_spk-lang/reco2num_spk2 exp/ivectors_test_2/plda_scores \
  exp/ivectors_test_2/plda_scores_num_spk-lang
# ***oracle VAD***:
diarization/cluster.sh --cmd "$train_cmd --mem 4G" \
  --reco2num-spk results/results_spk-lang/reco2num_spk \
  exp/ivectors_test_1_cheat/plda_scores exp/ivectors_test_1_cheat/plda_scores_num_spk-lang
diarization/cluster.sh --cmd "$train_cmd --mem 4G" --nj 9 \
  --reco2num-spk results/results_spk-lang/reco2num_spk2 \
  exp/ivectors_test_2_cheat/plda_scores exp/ivectors_test_2_cheat/plda_scores_num_spk-lang

# create reference rttm files with convert_utt2spk_and_segments_to_rttm.py
# --> language clusters: results/results_original/fullref.rttm 
# --> speaker-language clusters: results/results_spk-lang/fullref.rttm 

# combine results from both test subsets and evaluate together
# ***auto VAD/language clusters***:
cat exp/ivectors_test_1/plda_scores_num_spk/rttm \
  exp/ivectors_test_2/plda_scores_num_spk/rttm | md-eval.pl -1 -c 0.25 \
  -r results/results_original/fullref.rttm \
  -s - 2> results/results_original/num_spk.log > results/results_original/DER_num_spk.txt
# ***auto VAD/speaker-language clusters***:
cat exp/ivectors_test_1/plda_scores_num_spk-lang/rttm \
  exp/ivectors_test_2/plda_scores_num_spk-lang/rttm | md-eval.pl -1 -c 0.25 \
  -r results/results_spk-lang/fullref.rttm \
  -s - 2> results/results_spk-lang/num_spk.log > results/results_spk-lang/DER_num_spk.txt
# ***oracle VAD/language clusters***:
cat exp/ivectors_test_1_cheat/plda_scores_num_spk/rttm \
  exp/ivectors_test_2_cheat/plda_scores_num_spk/rttm | md-eval.pl -1 -c 0.25 \
  -r results/results_original/fullref.rttm \
  -s - 2> results/results_original/num_spk_cheat.log > results/results_original/DER_num_spk_cheat.txt
# ***oracle VAD/speaker-language clusters***:
cat exp/ivectors_test_1_cheat/plda_scores_num_spk-lang/rttm \
  exp/ivectors_test_2_cheat/plda_scores_num_spk-lang/rttm | md-eval.pl -1 -c 0.25 \
  -r results/results_spk-lang/fullref.rttm \
  -s - 2> results/results_spk-lang/num_spk_cheat.log > results/results_spk-lang/DER_num_spk_cheat.txt

