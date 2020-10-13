#!/user/bin/env bash

# Takes a directory of .sph files, converts them to .wav,
# and writes to the specified output dir.
# Note that $KALDI_ROOT	must be set in order to work.

if [ $# != 2 ]; then
  echo "Usage: sph_to_wav.sh <input-sph-dir> <output-wav-dir>"
  exit 1;
fi

sph_dir=$1
wav_dir=$2

for sph in $sph_dir/*.sph; do
  file_name=$(basename "$sph" .sph)
  sph2pipe -f wav -p -c 1 $sph $wav_dir/"${file_name}.wav"
done

sph_count() {
  ls $sph_dir/*.sph | wc -l 
}

wav_count() {
  ls $wav_dir/*.wav | wc -l
}

echo "$(sph_count) original .sph files"
echo "$(wav_count) .wav files written to $wav_dir"
