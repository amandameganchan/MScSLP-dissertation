#!/usr/bin/env bash

# Copyright          2013  Daniel Povey
#                    2016  David Snyder
#               2017-2018  Matthew Maciejewski
# Apache 2.0.

# This script extracts iVectors over a sliding window for a
# set of utterances, given features and a trained iVector
# extractor. This is used for speaker diarization. This is done
# using subsegmentation on the data directory. As a result, the
# files containing "spk" (e.g. utt2spk) in the data directory
# within the ivector directory are not referring to true speaker
# labels, but are referring to recording labels. For example,
# the spk2utt file contains a table mapping recording IDs to the
# sliding-window subsegments generated for that recording.

# Amanda:
# - edited num jobs to 4 and added CUDA_VISIBLE_DEVICES=$[g-1] to line 168 to work with cstr gpu
# - added hires dnn features to work with DNN-UBM
# - modified feature setup to work with SDCs

# Begin configuration section.
nj=4 
cmd="run.pl"
stage=0
window=1.5
period=0.75
pca_dim=
min_segment=0.5
hard_min=false
num_gselect=20 # Gaussian-selection using diagonal model: number of Gaussians to select
min_post=0.025 # Minimum posterior to use (posteriors below this are pruned out)
posterior_scale=1.0 # This scale helps to control for successve features being highly
                    # correlated.  E.g. try 0.1 or 0.3.
apply_cmn=true # If true, apply sliding window cepstral mean normalization
apply_deltas=true # If true, copy the delta options from the i-vector extractor directory.
                  # If false, we won't add deltas in this step. For speaker diarization,
		  # we sometimes need to write features to disk that already have various
		  # post-processing applied so adding deltas is no longer needed in this stage.
use_gpu=true
chunk_size=256
nnet_job_opt="$nnet_job_opt --gpu 1"
# End configuration section.

echo "$0 $@"  # Print the command line for logging

if [ -f path.sh ]; then . ./path.sh; fi
. parse_options.sh || exit 1;


if [ $# != 5 ]; then
  echo "Usage: $0 <extractor-dir> <dnn-model> <data> <data-dnn> <ivector-dir>"
  #echo " e.g.: $0 exp/extractor_2048 data/train exp/ivectors"
  echo "main options (for others, see top of script file)"
  echo "  --config <config-file>                           # config containing options"
  echo "  --cmd (utils/run.pl|utils/queue.pl <queue opts>) # how to run jobs."
  echo "  --window <window|1.5>                            # Sliding window length in seconds"
  echo "  --period <period|0.75>                           # Period of sliding windows in seconds"
  echo "  --pca-dim <n|-1>                                 # If provided, the whitening transform also"
  echo "                                                   # performs dimension reduction."
  echo "  --min-segment <min|0.5>                          # Minimum segment length in seconds per ivector"
  echo "  --hard-min <bool|false>                          # Removes segments less than min-segment if true."
  echo "                                                   # Useful for extracting training ivectors."
  echo "  --nj <n|10>                                      # Number of jobs"
  echo "  --stage <stage|0>                                # To control partial reruns"
  echo "  --num-gselect <n|20>                             # Number of Gaussians to select using"
  echo "                                                   # diagonal model."
  echo "  --min-post <min-post|0.025>                      # Pruning threshold for posteriors"
  echo "  --apply-cmn <true,false|true>                    # if true, apply sliding window cepstral mean"
  echo "                                                   # normalization to features"
  echo "  --apply-deltas <true,false|true>                 # If true, copy the delta options from the i-vector"
  echo "                                                   # extractor directory. If false, we won't add deltas"
  echo "                                                   # in this step. For speaker diarization, we sometimes"
  echo "                                                   # need to write features to disk that already have"
  echo "                                                   # various post-processing applied so adding deltas is"
  echo "                                                   # no longer needed in this stage."
  exit 1;
fi

srcdir=$1
nnet=$2
data=$3
data_dnn=$4
dir=$5

gpu_opt="--use-gpu=yes"

for f in $srcdir/final.ie $srcdir/final.ubm $data/feats.scp ; do
  [ ! -f $f ] && echo "No such file $f" && exit 1;
done

sub_data=$dir/subsegments_data
mkdir -p $sub_data
sub_data_dnn=$dir/subsegments_data_dnn
mkdir -p $sub_data_dnn

# Set up sliding-window subsegments
if [ $stage -le 0 ]; then
  if $hard_min; then
    awk -v min=$min_segment '{if($4-$3 >= min){print $0}}' $data/segments \
        > $dir/pruned_segments
    segments=$dir/pruned_segments
    awk -v min=$min_segment '{if($4-$3 >= min){print $0}}' $data_dnn/segments \
        > $dir/pruned_segments_dnn
    segments_dnn=$dir/pruned_segments_dnn
  else
    segments=$data/segments
    segments_dnn=$data_dnn/segments
  fi
  utils/data/get_uniform_subsegments.py \
      --max-segment-duration=$window \
      --overlap-duration=$(perl -e "print $window-$period") \
      --max-remaining-duration=$min_segment \
      --constant-duration=True \
      $segments > $dir/subsegments
  utils/data/subsegment_data_dir.sh $data \
      $dir/subsegments $sub_data
  utils/data/get_uniform_subsegments.py \
      --max-segment-duration=$window \
      --overlap-duration=$(perl -e "print $window-$period") \
      --max-remaining-duration=$min_segment \
      --constant-duration=True \
      $segments_dnn > $dir/subsegments_dnn
  utils/data/subsegment_data_dir.sh $data_dnn \
      $dir/subsegments_dnn $sub_data_dnn
fi

# Set various variables.
mkdir -p $dir/log
sub_sdata=$sub_data/split$nj;
utils/split_data.sh $sub_data $nj || exit 1;

sub_sdata_dnn=$sub_data_dnn/split$nj;
utils/split_data.sh $sub_data_dnn $nj || exit 1;

#if $apply_deltas; then
#  delta_opts=`cat $srcdir/delta_opts 2>/dev/null`
#else
#  delta_opts="--delta-order=0"
#fi

## Set up features.
#if $apply_cmn; then
#  feats="ark,s,cs:add-deltas $delta_opts scp:$sub_sdata/JOB/feats.scp ark:- | apply-cmvn-sliding --norm-vars=false --center=true --cmn-window=300 ark:- ark:- |"
#else
#  feats="ark,s,cs:add-deltas $delta_opts scp:$sub_sdata/JOB/feats.scp ark:- |"
#fi

feats="ark,s,cs:apply-cmvn-sliding --norm-vars=false --center=true --cmn-window=300 scp:$sub_sdata/JOB/feats.scp ark:- | add-deltas-sdc ark:- ark:- |"

# set up nnet features
nnet_feats="ark,s,cs:apply-cmvn-sliding --center=true scp:$sub_sdata_dnn/JOB/feats.scp ark:- |"

if [ $stage -le 1 ]; then
  echo "$0: extracting iVectors"
  #dubm="fgmm-global-to-gmm $srcdir/final.ubm -|"

  #$cmd JOB=1:$nj $dir/log/extract_ivectors.JOB.log \
  #  gmm-gselect --n=$num_gselect "$dubm" "$feats" ark:- \| \
  #  fgmm-global-gselect-to-post --min-post=$min_post $srcdir/final.ubm "$feats" \
  #     ark,s,cs:- ark:- \| scale-post ark:- $posterior_scale ark:- \| \
  #  ivector-extract --verbose=2 $srcdir/final.ie "$feats" ark,s,cs:- \
  #    ark,scp,t:$dir/ivector.JOB.ark,$dir/ivector.JOB.scp || exit 1;

 # took this out from after $nnet line:
 #  \| select-voiced-frames ark:- scp,s,cs:$sub_sdata/$g/vad.scp ark:- \
  for g in $(seq $nj); do
    $cmd $nnet_job_opt $dir/log/extract_ivectors.$g.log \
      CUDA_VISIBLE_DEVICES=$[g-1] nnet-am-compute $gpu_opt --apply-log=true --chunk-size=${chunk_size} \
        $nnet "`echo $nnet_feats | sed s/JOB/$g/g`" ark:- \
        \| logprob-to-post --min-post=$min_post ark:- ark:- \| \
        scale-post ark:- $posterior_scale ark:- \| \
        ivector-extract --verbose=2 $srcdir/final.ie \
        "`echo $feats | sed s/JOB/$g/g`" ark,s,cs:- \
        ark,scp,t:$dir/ivector.$g.ark,$dir/ivector.$g.scp || exit 1 &
  done
  wait
fi

if [ $stage -le 2 ]; then
  echo "$0: combining iVectors across jobs"
  for j in $(seq $nj); do cat $dir/ivector.$j.scp; done >$dir/ivector.scp || exit 1;
  cp $sub_data/{segments,spk2utt,utt2spk} $dir
fi

if [ $stage -le 3 ]; then
  echo "$0: Computing mean of iVectors"
  $cmd $dir/log/mean.log \
    ivector-mean scp:$dir/ivector.scp $dir/mean.vec || exit 1;
fi

if [ $stage -le 4 ]; then
  if [ -z "$pca_dim" ]; then
    pca_dim=-1
  fi
  echo "$0: Computing whitening transform"
  $cmd $dir/log/transform.log \
    est-pca --read-vectors=true --normalize-mean=false \
      --normalize-variance=true --dim=$pca_dim \
      scp:$dir/ivector.scp $dir/transform.mat || exit 1;
fi
