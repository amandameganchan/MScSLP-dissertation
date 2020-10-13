# takes desired duration and segments file as input
# writes segments of desired duration or longer to file

if [ $# != 3 ]; then
  echo "Usage: get_utts_of_dur.sh <min-dur-in-msec> <segments-file> <out-file>"
  exit 1;
fi 

dur=$1
segments=$2
out_file=$3

line_n=0
tot_lines=$(wc -l $segments | cut -d ' ' -f 1 | xargs)

total=0

while read line || [[ -n $line ]]; do
    
    line_n=$(($line_n+1))
    echo -ne "$line_n/$tot_lines \r"
    
    start_time=$(( 10#$(echo $line | cut -d ' ' -f 3 | cut -d '.' -f 1) * 1000))
    start_time=$(( 10#$start_time + 10#$(echo $line | cut -d ' ' -f 3 | cut -d '.' -f 2) ))
    end_time=$(( 10#$(echo $line | cut -d ' ' -f 4 | cut -d '.' -f 1) * 1000)) 
    end_time=$(( 10#$end_time + 10#$(echo $line | cut -d ' ' -f 4 | cut -d '.' -f 2) ))

    add_time=$((10#$end_time - 10#$start_time))
    
    if [[ "$add_time" -gt "$dur" ]]; then
      echo $line >> $out_file
      total=$((10#$total + 10#$add_time)) 
    fi

done <$segments

denom=$(wc -l $out_file | cut -d ' ' -f 1 | xargs)
total_sec=$((10#$total / 1000))
avg=$((10#$total_sec / 10#$denom)) 
total_min=$((10#$total_sec / 60))
total_hr=$((10#$total_min / 60))
total_min=$((10#$total_min % 60))

echo "average segment length: $avg s"
echo "total time: $total_hr:$total_min"
