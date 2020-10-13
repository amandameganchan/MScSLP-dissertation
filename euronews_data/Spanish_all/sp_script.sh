# 2nd attempt
# made per word segments and then concat here within half a second and grab segments longer than 5s
bash ../concat_segments_longer.sh 500 "spanish" kaldi_files/segments kaldi_files/text
bash ../get_utts_of_dur.sh 5000 new_files_spanish/segments 5sec
# 1st attempt
# exactly adjacent word segments (too short on average)
#bash make_text+segments_lang.sh "spanish" /disk/scratch3/s1983587/euronews_data/Spanish_all/ctm /disk/scratch3/s1983587/euronews_data/Spanish_all/lgn /disk/scratch3/s1983587/euronews_data/Spanish_all/wav
