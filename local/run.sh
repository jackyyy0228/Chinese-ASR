#!/bin/bash
AUDIO_DATA_PREP=false
LANG_DATA_PREP=false
EXTRACT_MFCC=true

TRAIN_MONO=true
TRAIN_TRI=true
TRAIN_CHAIN=true

nj=8 #number of job parallel running

if [ $AUDIO_DATA_PREP = true ] ; then
  echo "Preparing audio data..."
  for corpus in cyberon_chinese cyberon_english PTS NER TOCFL seame Tl ; do
    local/data/data_prep_${corpus}.sh
  done
fi

if [ $LANG_DATA_PREP = true ] ; then
  echo "Preparing lang data..."
  #prepare dictionary lexicon
  local/prepare_ch_dict.sh
  # Phone Sets, questions, L compilation                                                                                                      
  utils/prepare_lang.sh data/local/dict "<UNK>" data/local/lang data/lang
  # LM training
  local/hkust_train_lms.sh 
  #G compilation, check LG composition
  local/hkust_format_data.sh
fi

. ./path.sh
. ./cmd.sh

if [ $EXTRACT_MFCC = true ] ; then
  mfccdir=data/mfcc_pitch
  mfcc_pitch_hires_dir=data/mfcc_pitch_hires
  mfcc_hires_dir=data/mfcc_hires

  mkdir -p $mfccdir
  mkdir -p $mfcc_pitch_hires_dir
  mkdir -p $mfcc_hires_dir

  combine48=''
  combine43=''
  combine40=''

  for corpus in cyberon_chinese_train cyberon_english_train PTS NER TOCFL seame Tl ; do
    ##Extract MFCC39 + pitch9 feature
    data=./data/$corpus/mfcc39_pitch9
    combine48="$data $combine48"

    steps/make_mfcc_pitch_online.sh --cmd "$train_cmd" --nj $nj $data exp/make_mfcc/$corpus $mfccdir || exit 1;
    steps/compute_cmvn_stats.sh $data exp/make_mfcc/$corpus $mfccdir || exit 1;
    
    ##Extract MFCC40 + pitch3 feature
    data=./data/$corpus/mfcc40_pitch3
    combine43="$data $combine43"

    utils/copy_data_dir.sh data/$corpus/mfcc39_pitch9 $data
    steps/make_mfcc_pitch_online.sh --cmd "$train_cmd" --nj $nj --mfcc-config conf/mfcc_hires.conf \
      $data exp/make_hires/$corpus $mfcc_pitch_hires_dir || exit 1;
    steps/compute_cmvn_stats.sh $data exp/make_pitch_hires/$corpus $mfcc_pitch_hires_dir || exit 1;
    # create MFCC data dir without pitch to extract iVector
    combine40="data/$corpus/mfcc40 $combine40"
    utils/data/limit_feature_dim.sh 0:39 $data data/$corpus/mfcc40 || exit 1;
    steps/compute_cmvn_stats.sh data/$corpus/mfcc40 exp/make_hires/$corpus $mfcc_hires_dir || exit 1;
    echo $combine40 $combine43 $combine48
  done
  utils/combine_data.sh data/train/mfcc_39_pitch9 $combine48
  utils/combine_data.sh data/train/mfcc_40_pitch3 $combine43
  utils/combine_data.sh data/train/mfcc40 $combine40
  
  # make no english audio dataset (only english alphabet and numbers)
  combine48=''
  combine43=''
  combine40=''
  for corpus in cyberon_chinese_train PTS NER Tl ; do
    data=./data/$corpus/mfcc39_pitch9
    combine48="$data $combine48"
    data=./data/$corpus/mfcc40_pitch3
    combine43="$data $combine43"
    data=./data/$corpus/mfcc40
    combine40="$data $combine40"
  done
  utils/combine_data.sh data/train_no_eng/mfcc_39_pitch9 $combine48
  utils/combine_data.sh data/train_no_eng/mfcc_40_pitch3 $combine43
  utils/combine_data.sh data/train_no_eng/mfcc40 $combine40
fi
exit 1
if [ TRAIN_MONO = true ] ; then
fi
  


if [ TRAIN_TRI = true ] ; then
fi

if [ TRAIN_CHAIN = true ] ; then
fi


