# 2nd attempt
# made per word segments and then concat here within half a second and grab segments longer than 5s
bash ../concat_segments_longer.sh 500 "polish" kaldi_files/segments kaldi_files/text
bash ../get_utts_of_dur.sh 5000 new_files_polish/segments 5sec
# 1st attempt
# exactly adjacent word segments (too short on average) 
#bash make_text+segments_lang.sh "polish" /disk/scratch3/s1983587/euronews_data/Polish_all/ctm /disk/scratch3/s1983587/euronews_data/Polish_all/lgn /disk/scratch3/s1983587/euronews_data/Polish_all/wav
