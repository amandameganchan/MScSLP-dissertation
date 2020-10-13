for i in $( ls ); do
if [[ -f $i ]]; then
   sed -i -e 's/^...-//' $i
fi
done
