#!/usr/bin/bash

# Takes euronews ctm and lgn file directories as input
# and parses the information to recompile in kaldi-friendly
# formatted files: segments, text, utt2spk.
# For use with DNN trained for language ID system UBM.
# *modified old version script that makes segments of one word each 
# (this is how they are given in original Euronews documentation) 

if [ $# != 2 ]; then
  echo "Usage: make_text+segments.sh <ctm-file-directory> <lgn-file-directory>"
  exit 1;
fi 

# read in file directories
ctm_files=$1
lgn_files=$2

# create output dir
mkdir -p segments_out_files_perword

file_n=0
tot_files=$(ls $ctm_files/*.ctm | wc -l | cut -d ' ' -f 1 | xargs)

for file in $ctm_files/*.ctm; do
  
  file_n=$(($file_n+1)) 
  echo -ne "$file_n/$tot_files \r"

  file_name=$(basename "$file" .ctm)
  lgn=$(echo "$lgn_files/$file_name.lgn") 

  segment_n=0

  while read line || [[ -n $line ]]; do
    
    word=$(echo $line | cut -d ' ' -f 5)
    if [[ "$word" == "@bg" ]]; then
      continue
    fi

    start_time=$(echo $line | cut -d ' ' -f 3)
    lgn_line=$(grep "$(echo $start_time | grep -o '^[0-9]*\.[0-9]')" $lgn | grep "$word")
    lgn_valid=$(echo $lgn_line | tr -s ' ' | cut -d ' ' -f 1) 
    if [[ "$lgn_valid" != "C" ]]; then
      continue
    fi

    seg_dur=$(echo $line | cut -d ' ' -f 4)
    end_sec=$((10#$(echo $start_time | cut -d '.' -f 1)+10#$(echo $seg_dur | cut -d '.' -f 1)))
    end_msec=$((10#$(echo $start_time | cut -d '.' -f 2)+10#$(echo $seg_dur | cut -d '.' -f 2)))
    
    if [ "$end_msec" -gt 999 ]; then
      end_sec=$((10#$end_sec+10#$((10#$end_msec/1000))))
      end_msec=$(printf "%03d" $((10#$end_msec%1000)))
    fi

    end_time=$(echo "$end_sec.$end_msec")

#    echo "$file_name $start_time $end_time $word" >> temp_processing_file    

#  done <$file

#  counter=0
#  last_line=$(wc -l temp_processing_file | cut -d ' ' -f 1 | xargs)  
#  segment_n=0
#  while read temp_line || [[ -n $temp_line ]]; do
  
#    counter=$(($counter+1)) 
#    text=$(echo $temp_line | cut -d ' ' -f 4)
#    current_start=$(echo $temp_line | cut -d ' ' -f 2)
#    current_end=$(echo $temp_line | cut -d ' ' -f 3)
    
#    if [ "$counter" == 1 ]; then
#      transcript="${text}"
#      prev_start="${current_start}"
#      prev_end="${current_end}"
#      continue
#    fi

#    if [ "$current_start" == "$prev_end" ]
#     then
#      transcript="${transcript} ${text}"     
#      prev_end="${current_end}"
#     else
    segment_n=$(($segment_n+1)) 
    printf -v n "%04d" $segment_n
    seg_name=$(echo "$file_name-$n")
    echo "$seg_name $file_name $start_time $end_time" >> segments_out_files_perword/segments
    echo "$seg_name $word" >> segments_out_files_perword/text
    echo "$seg_name $seg_name" >> segments_out_files_perword/utt2spk
#      transcript="${text}"
#      prev_start="${current_start}"
#      prev_end="${current_end}"
#    fi
    
#    if [ "$counter" == "$last_line" ]; then
#      segment_n=$(($segment_n+1))
#      printf -v n "%04d" $segment_n 
#      seg_name=$(echo "$file_name-$n")
#      echo "$seg_name $file_name $prev_start $prev_end" >> segments_out_files/segments
#      echo "$seg_name $transcript" >> segments_out_files/text
#      echo "$seg_name $seg_name" >> segments_out_files/utt2spk
#    fi

#  done <temp_processing_file

#  rm temp_processing_file

  done<$file
done
