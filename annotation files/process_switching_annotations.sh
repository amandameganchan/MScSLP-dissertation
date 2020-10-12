#!/usr/bin/bash

# Takes an annotation file and corresponding recording ID as input
# and parses the information to recompile in kaldi-friendly formatted
# files: segments, utt2spk, and utt2lang.
# For use with a language ID system. Input annotation file
# should be in the format: speaker;language;start-time;end-time
if [ $# != 2 ]; then
  echo "Usage: process_switching_annotations.sh <annotation-file> <recording-ID>"
  exit 1;
fi 

# read in annotation file and recordingID
# set segment counter = 0
ann_file=$1
recID=$2
segment_counter=0

# for each line in file:
while read line || [[ -n $line ]]; do

  # parse each column (speaker/language/start time/end time) and store in vars
  # whitespace stripped from both ends
  # speaker and language fields converted to lower case
  spkr=$(echo $line | cut -d ';' -f 1 | tr '[:upper:]' '[:lower:]' | xargs)
  lang=$(echo $line | cut -d ';' -f 2 | tr '[:upper:]' '[:lower:]' | xargs)
  begin=$(echo $line | cut -d ';' -f 3 | xargs)
  end=$(echo $line | cut -d ';' -f 4 | xargs) 

  # if speaker == man | woman
  #   store m or w in var
  # else continue to next line
  case $spkr in
  "man")
    spkr='m' ;;
  "woman")
    spkr='w' ;;
  *)
    continue ;;
  esac 

  # if language field contains the word (english|french|german|italian|polish|spanish) 
  #   store the lower-cased lang in var
  # else continue to next line
  case $lang in
  *"english"*)
    lang="english" ;;
  *"french"*)
    lang="french" ;;
  *"german"*) 
    lang="german" ;;
  *"italian"*)
    lang="italian" ;;
  *"polish"*) 
    lang="polish" ;; 
  *"spanish"*)
    lang="spanish" ;;
  *)
    continue ;;
  esac

  # convert start time to seconds and store in var
  b_hrs=$(echo $begin | cut -d ':' -f 1 | xargs)
  b_mins=$(echo $begin | cut -d ':' -f 2 | xargs)
  b_secs_f=$(echo $begin | cut -d ':' -f 3 | xargs)
  b_secs=$(echo $b_secs_f | cut -d '.' -f 1 | xargs)
  b_decimal=$(echo $b_secs_f | cut -d '.' -f 2 | xargs) 
  b_total=$((10#$b_hrs*3600+10#$b_mins*60+10#$b_secs))
  begin=$(echo "$b_total.$b_decimal")   

  # convert end time to seconds and store in var 
  e_hrs=$(echo $end | cut -d ':' -f 1 | xargs)
  e_mins=$(echo $end | cut -d ':' -f 2 | xargs)
  e_secs_f=$(echo $end | cut -d ':' -f 3 | xargs) 
  e_secs=$(echo $e_secs_f | cut -d '.' -f 1 | xargs)
  e_decimal=$(echo $e_secs_f | cut -d '.' -f 2 | xargs)
  e_total=$((10#$e_hrs*3600+10#$e_mins*60+10#$e_secs))
  end=$(echo "$e_total.$e_decimal")   

  # set speaker ID, utterance ID, filename 
  cplID=$(echo $recID | cut -c 2)
  spkrID=$(echo "c$cplID$spkr")

  segment_counter=$(($segment_counter+1)) 
  printf -v n "%03d" $segment_counter
  uttID=$(echo "$spkrID-$recID-$n")    

  filename=$(echo $ann_file | cut -d '.' -f 1)   

  # write to segments file:
  echo "$uttID $recID $begin $end" >> segments  

  # write to utt2spk file:
  echo "$uttID $spkrID" >> utt2spk

  # write to utt2lang file:
  echo "$uttID $lang" >> utt2lang

done <$ann_file
