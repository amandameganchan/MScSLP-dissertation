in_file=$1
out_file=$2
while read line; do
if echo $line | grep -q "_po_"; then
 echo "$line polish" >> $out_file
elif echo $line | grep -q "_de_"; then
 echo "$line german" >> $out_file
elif echo $line | grep -q "_en_"; then
 echo "$line english" >> $out_file
elif echo $line | grep -q "_es_"; then
 echo "$line spanish" >> $out_file
elif echo $line | grep -q "_fr_"; then
 echo "$line french" >> $out_file
elif echo $line | grep -q "^FR"; then
 echo "$line french" >> $out_file
elif echo $line | grep -q "^GE"; then
 echo "$line german" >> $out_file
elif echo $line | grep -q "^PL"; then
 echo "$line polish" >> $out_file
elif echo $line | grep -q "^SP"; then
 echo "$line spanish" >> $out_file
fi
done < $in_file
