#!/bin/bash

if [ $# != 2 ]; then
  echo " Usage : data_prep_wav.sh <wav_dir> <decode_dir> "
fi

wav=$1
data=$2

mkdir -p $data

python3 local/data/data_prep_wav.py $wav $data
cat $data/utt2spk | utils/utt2spk_to_spk2utt.pl > $data/spk2utt || exit 1;
utils/fix_data_dir.sh $data || exit 1;
