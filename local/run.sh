#!/bin/bash
AUDIO_DATA_PREP=true
LANG_DATA_PREP=true
EXTRACT_MFCC=true

TRAIN_MONO=true
TRAIN_TRI=true
TRAIN_CHAIN=true

nj=8 #number of job parallel running

if [ AUDIO_DATA_PREP=true ] ; then
  echo "Preparing audio data..."
  for corpus in cyberon_chinese cyberon_english PTB NER EatMic ; do
    local/data/data_prep_${corpus}.sh
  done
  combine_data
fi
if [ AUDIO_DATA_PREP=true ] ; then
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

if [ EXTRACT_MFCC=true ] ; then
  for corpus in 
fi

if [ TRAIN_MONO=true ] ; then
fi
  


if [ TRAIN_TRI=true ] ; then
fi

if [ TRAIN_CHAIN=true ] ; then
fi


