Roberto Gretter, FBK, Spring-Summer-Fall 2013

Euronews WEB - Train100H10L data description

These  data  come  from Euronews  webpages  (http://fr.euronews.com/).
They  are composed  by  videos  in 10  different  languages, each  one
commented  by  a  reference  text.   The comment  could  be  either  a
relatively  precise  manual  orthographic  transcription,  or  just  a
summary, or a  long text related to the news  but not corresponding to
the audio.

The data are those published from  January 1st, 2013 to May 31st, 2013
(5 months) and they roughly correspond to 100 hours of speech for each
language, except  for Polish.  For Polish, whose  published videos are
sparse, we used videos published from January 1st, 2012 to March 31st,
2013 (15  months) roughly  corresponding to 60  hours of  speech.  All
these data should be used for training of acoustic models.

We did the following processing for all the languages (thanks to PJIIT
people for their help with Polish):

1) download the video and the corresponding reference text from 
   the website
2) find the cross lingual links (same news in different language)
3) extract from the video the audio, in sphere format
4) normalize the reference text 
5) consider all the texts from the news
6) build a small LM
7) run our ASR on the audio
8) align reference text with ASR output
9) compute some parameter for each file (duration/words, wer,
   #words ref, #words rec)


Data were uploaded on the KIT server, and include for each video:
 .sph  file - audio in sphere format
 .info file - original text associated with the news (normally
              title + content, 2 lines)
 .ref  file - reference text (UTF-8 text obtained by processing
              .info file in order to remove punctuation, handle
              acronyms (uppercase: LKW, US), expand numbers (e.g. 
              777 -> sieben hundert sieben und siebzig), etc.
 .ctm  file - ASR output, UTF-8, same linguistic processing as .ref;
              silence is indicated with @bg; some sample lines are:
              20130101_20130531_de_aaaa 1 1.770 0.255 @bg
              20130101_20130531_de_aaaa 1 2.025 0.400 auch
              20130101_20130531_de_aaaa 1 2.425 0.020 @bg
              20130101_20130531_de_aaaa 1 2.445 0.340 so
              20130101_20130531_de_aaaa 1 2.785 0.260 kann
              20130101_20130531_de_aaaa 1 3.045 0.150 man
 .lgn  file - alignment between .ref and .ctm files. apart comment
              lines (beginning with "#"), each line contains 4 tokens:
              - D I S C (Deletion, Insertion, Substitution, Correct)
              - beginning time (from the .ctm)
              - reference word (or "-"), from .ref file
              - asr output word (or "-"), from .ctm file. @bg means silence
              Some samples of rows follow:
#     time ref_word        asr_output      
D     0.00 LKW             -               
D     0.00 will            -               
D     0.00 auf             -               
S     0.00 wenden          @bg             
S     0.04 zwei            ich             
S     0.61 Tote            @bg             
C     1.60 lettischer      lettischer      
C     2.10 LKW             LKW             
C     2.54 Fahrer          Fahrer          
C    15.88 blieb           blieb           
C    16.12 -               @bg             
C    16.14 unverletzt      unverletzt      
I    56.38 -               Hund            
I    56.55 -               gebissen   
# u: 113 e: 13 s: 6 i: 1 d: 6 c: 101 ua: 88.50% pc: 89.38% uer: 11.50%
# U: 113 E: 13 S: 6 5.31% I: 1 0.88% D: 6 5.31% C: 101 89.38% UA: 88.50% UER: 11.50%


In addition, there  is one file containing the md5sum  for each of the
other files  and one summary  file containing the following  info (one
row for each file):
 words/sec=    # number of reference words / duration in seconds
 wer=          # word error rate (result of the aligment from .ref
               # and .ctm files)
 dur(s)=       # duration in seconds of the audio file
 refwords=     # number of reference words
 recwords=     # number of recognized words
 fileid=       # file identificator
Some samples:
words/sec=   2.24 wer=  27.04% dur(s)= 142.05 refwords=  318 recwords=  422 fileid= German/20130101_20130531_de_aaad
words/sec=   2.89 wer=  38.69% dur(s)=  58.04 refwords=  168 recwords=  155 fileid= German/20130101_20130531_de_aaae

Foreach language (e.g. German) the following files were uploaded on the KIT server:
 German100hSpeech.tar     : huge, containing .sph files
 German100hSpeech.md5sum  : md5sum result for speech files
 German100hText.tgz       : contains text files (.info, .ref, .ctm, .lgn)
 German100hText.md5sum    : md5sum result for text files
 German100h.rep           : summary file

The following table contains the amount of data for every language, where:

#files:         number of news
tot_speech:     sum of the duration of the whole news: it includes
                silences, music, etc.
#ref_words      total number of words of the reference text, normalized
#rec_words      total number of words resulting from an ASR, normalized
#common_words   total number of common words resulting from the alignment
                of ref and rec words 
aligned_speech  sum of the duration of the common words; as it is computed
                at word level it does not include silence, music, etc.

language  #files  tot_speech  #ref_words  #rec_words  #common_words  aligned_speech
Arabic      4406   107:20:59     650,146     759,873        343,785        39:46:11
English     4512   112:16:27     973,210   1,010,095        684,872        58:58:43
French      4434   108:54:36     954,242   1,134,009        764,333        58:34:56
German      4438   108:31:23     809,289     914,212        649,375        63:56:36
Italian     4464   110:33:51     900,291   1,020,591        754,835        64:39:29
Polski      2626    58:31:08     350,729     456,704        272,631        28:11:49
Portuguese  4431   108:01:28     841,148     888,918        430,120        38:26:05
Russian     4418   107:40:27     714,363     830,600        598,251        63:40:46
Spanish     4465   109:14:49     939,408   1,056,793        792,339        64:47:57
Turkiye     4387   106:28:33     683,041     773,655        550,038        59:15:18

