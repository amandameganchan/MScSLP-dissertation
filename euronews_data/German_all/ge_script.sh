# 2nd attempt
# made per word segments and then concat here within half a second and grab segments longer than 5s
bash ../concat_segments_longer.sh 500 "german" kaldi_files/segments kaldi_files/text
bash ../get_utts_of_dur.sh 5000 new_files_german/segments 5sec
# 1st attempt
# exactly adjacent word segments (too short on average)
#bash make_text+segments_lang.sh "german" /disk/scratch3/s1983587/euronews_data/German_all/ctm /disk/scratch3/s1983587/euronews_data/German_all/lgn /disk/scratch3/s1983587/euronews_data/German_all/wav
