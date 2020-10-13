#!/usr/bin/env bash

# Make the features.
# modified by Amanda for monolingual (English) trained DNN-UBM experiment

. ./cmd.sh

stage=1
set -e
. ./cmd.sh
. ./path.sh
. ./utils/parse_options.sh

mkdir -p exp/enws_mono/nnet2_online

if [ $stage -le 1 ]; then
  # this shows how you can split across multiple file-systems.  we'll split the
  # MFCC dir across multiple locations.  You might want to be careful here, if you
  # have multiple copies of Kaldi checked out and run the same recipe, not to let
  # them overwrite each other.
  mfccdir=mfcc/enws_mono
  if [[ $(hostname -f) == *.clsp.jhu.edu ]] && [ ! -d $mfccdir/storage ]; then
    date=$(date +'%m_%d_%H_%M')
    utils/create_split_dir.pl /export/b0{1,2,3,4}/$USER/kaldi-data/egs/fisher_english-$date/s5/$mfccdir/storage $mfccdir/storage
  fi
  utils/copy_data_dir.sh data/enws_mono/train_asr data/enws_mono/train_hires_asr
  steps/make_mfcc.sh --mfcc-config conf/mfcc_hires.conf \
      --cmd "$train_cmd" data/enws_mono/train_hires_asr exp/enws_mono/make_hires/train $mfccdir || exit 1;
fi
