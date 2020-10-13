#mkdir within_lexicon
#cut -d ' ' -f 2- current_files/text | tr ' ' '\n' | tr [:upper:] [:lower:] | sort | uniq > within_lexicon/enws_words
#grep -o '^\S*' dict/lexicon.txt | sort | uniq > within_lexicon/lex_words
#comm -12 within_lexicon/lex_words within_lexicon/enws_words > within_lexicon/common_words
#comm -23 within_lexicon/enws_words within_lexicon/common_words > within_lexicon/non-matches
#cat current_files/text | tr [:upper:] [:lower:] > within_lexicon/text
#while read line; do echo "\b$line\b" >> within_lexicon/tempfile; done < within_lexicon/non-matches
grep -vf within_lexicon/remove_words within_lexicon/usable_text_original > within_lexicon/usable_text_original_checked
cut -d ' ' -f 1 within_lexicon/usable_text_original_checked > within_lexicon/usable_ids_original_checked
grep -Ff within_lexicon/usable_ids_original_checked within_lexicon/usable_segs_original > within_lexicon/usable_segs_original_checked
#bash ../../avg_seg_dur.sh within_lexicon/usable_segs_original

