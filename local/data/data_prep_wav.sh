#!/bin/bash

if [ $# != 2 ]; then
  echo " Usage : data_prep_wav.sh <wav_dir> <decode_dir> "
fi
data=$2
wav=$1
python3 local/data/data_prep_wav.py $wav $data
cat $data/utt2spk | utils/utt2spk_to_spk2utt.pl > $data/spk2utt || exit 1;
utils/fix_data_dir.sh $data || exit 1;
