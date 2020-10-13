#!/usr/bin/bash

# Takes an existing segments file and concats adjacent segments within a given threshold.
# Out: segments, text, utt2lang, utt2spk
if [ $# != 4 ]; then
  echo "Usage: concat_segments_longer.sh <threshold-in-msec> <lang> <segments-file> <text-file>"
  exit 1;
fi 

# read in lang + file directories
threshold=$1
lang=$2
segments=$3
text_file=$4

# create output dir
mkdir -p new_files_$lang
out_dir=new_files_$lang

line_n=0
tot_lines=$(wc -l $segments | cut -d ' ' -f 1 | xargs)
segment_n=0
prev_file=""

while read line || [[ -n $line ]]; do
  
  line_n=$(($line_n+1)) 
  echo -ne "$line_n/$tot_lines \r" 
  
  file_name=$(echo $line | cut -d ' ' -f 2) 
  utt_id=$(echo $line | cut -d ' ' -f 1)
  current_start=$(echo $line | cut -d ' ' -f 3)
  current_end=$(echo $line | cut -d ' ' -f 4)
  text=$(grep $utt_id $text_file | cut -d ' ' -f 2-)    

  if [[ "$prev_file" != "$file_name" ]]; then
    if [[ "$line_n" != 1 ]]; then
      segment_n=$(($segment_n+1))
      printf -v n "%04d" $segment_n
      seg_name=$(echo "$prev_file-$n")
      echo "$seg_name $prev_file $prev_start $prev_end" >> $out_dir/segments
      echo "$seg_name $transcript" >> $out_dir/text
      echo "$seg_name $seg_name" >> $out_dir/utt2spk
      echo "$seg_name $lang" >> $out_dir/utt2lang
    fi
    segment_n=0
    transcript="${text}"
    prev_start="${current_start}"
    prev_end="${current_end}"
    prev_file="${file_name}" 
    continue
  fi

  prev_time=$((10#$(echo $prev_end | cut -d '.' -f 1) * 1000 + 10#$(echo $prev_end | cut -d '.' -f 2))) 
  current_time=$((10#$(echo $current_start | cut -d '.' -f 1) * 1000 + 10#$(echo $current_start | cut -d '.' -f 2)))
  time_diff=$((10#$current_time - 10#$prev_time))

  if [[ "$time_diff" -lt "$threshold" ]] 
   then
    transcript="${transcript} ${text}"     
    prev_end="${current_end}"
   else
    segment_n=$(($segment_n+1)) 
    printf -v n "%04d" $segment_n
    seg_name=$(echo "$file_name-$n")
    echo "$seg_name $file_name $prev_start $prev_end" >> $out_dir/segments
    echo "$seg_name $transcript" >> $out_dir/text
    echo "$seg_name $seg_name" >> $out_dir/utt2spk
    echo "$seg_name $lang" >> $out_dir/utt2lang
    transcript="${text}"
    prev_start="${current_start}"
    prev_end="${current_end}"
  fi
    
  if [[ "$line_n" == "$tot_lines" ]]; then
    segment_n=$(($segment_n+1))
    printf -v n "%04d" $segment_n 
    seg_name=$(echo "$file_name-$n")
    echo "$seg_name $file_name $prev_start $prev_end" >> $out_dir/segments
    echo "$seg_name $transcript" >> $out_dir/text
    echo "$seg_name $seg_name" >> $out_dir/utt2spk
    echo "$seg_name $lang" >> $out_dir/utt2lang
  fi
 
done<$segments
