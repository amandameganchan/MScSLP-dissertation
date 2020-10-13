#!/bin/bash 
#

if [ $# != 1 ]; then
  echo "Usage: fisher_create_test_lang.sh <data-dir>"
  exit 1;
fi 

data_dir=$1

if [ -f path.sh ]; then . ./path.sh; fi

mkdir -p $data_dir/lang_test

arpa_lm=$data_dir/local/lm/3gram-mincount/lm_unpruned.gz
[ ! -f $arpa_lm ] && echo No such file $arpa_lm && exit 1;

mkdir -p $data_dir/lang_test
cp -r $data_dir/lang/* $data_dir/lang_test

# grep -v '<s> <s>' etc. is only for future-proofing this script.  Our
# LM doesn't have these "invalid combinations".  These can cause 
# determinization failures of CLG [ends up being epsilon cycles].
# Note: remove_oovs.pl takes a list of words in the LM that aren't in
# our word list.  Since our LM doesn't have any, we just give it
# /dev/null [we leave it in the script to show how you'd do it].
gunzip -c "$arpa_lm" | utils/find_arpa_oovs.pl $data_dir/lang/words.txt > $data_dir/local/lm/3gram-mincount/oovs.txt

gunzip -c "$arpa_lm" | \
   grep -v '<s> <s>' | \
   grep -v '</s> <s>' | \
   grep -v '</s> </s>' | \
   arpa2fst - | fstprint | \
   utils/remove_oovs.pl $data_dir/local/lm/3gram-mincount/oovs.txt | \
   utils/eps2disambig.pl | utils/s2eps.pl | fstcompile --isymbols=$data_dir/lang_test/words.txt \
     --osymbols=$data_dir/lang_test/words.txt  --keep_isymbols=false --keep_osymbols=false | \
    fstrmepsilon | fstarcsort --sort_type=ilabel > $data_dir/lang_test/G.fst
  fstisstochastic $data_dir/lang_test/G.fst


echo  "Checking how stochastic G is (the first of these numbers should be small):"
fstisstochastic $data_dir/lang_test/G.fst 

## Check lexicon.
## just have a look and make sure it seems sane.
echo "First few lines of lexicon FST:"
fstprint   --isymbols=$data_dir/lang/phones.txt --osymbols=$data_dir/lang/words.txt $data_dir/lang/L.fst  | head

echo Performing further checks

# Checking that G.fst is determinizable.
fstdeterminize $data_dir/lang_test/G.fst /dev/null || echo Error determinizing G.

# Checking that L_disambig.fst is determinizable.
fstdeterminize $data_dir/lang_test/L_disambig.fst /dev/null || echo Error determinizing L.

# Checking that disambiguated lexicon times G is determinizable
# Note: we do this with fstdeterminizestar not fstdeterminize, as
# fstdeterminize was taking forever (presumbaly relates to a bug
# in this version of OpenFst that makes determinization slow for
# some case).
fsttablecompose $data_dir/lang_test/L_disambig.fst $data_dir/lang_test/G.fst | \
   fstdeterminizestar >/dev/null || echo Error

# Checking that LG is stochastic:
fsttablecompose $data_dir/lang/L_disambig.fst $data_dir/lang_test/G.fst | \
   fstisstochastic || echo "[log:] LG is not stochastic"


echo "$0 succeeded"

