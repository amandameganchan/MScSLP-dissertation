#!/usr/bin/bash

# takes a VAD (ark) file and changes the non-speech
# noise symbol (1) to the speech noise symbol (2) 

arkdir=$1
outdir=$2
mkdir -p $outdir
mkdir -p temp_files

for ark in $arkdir/*
do
  copy-vector ark:$ark ark,t:temp.txt
  sed -i -e 's/\b1\b/2/g' temp.txt
  copy-vector ark,t:temp.txt ark:$outdir/$(basename "$ark")
  mv temp.txt temp_files/$(basename "$ark" .ark)-temp.txt 
done
