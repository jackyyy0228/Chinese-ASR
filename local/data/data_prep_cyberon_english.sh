#!/bin/bash
. ./local/data/corpus_path.sh

for part in cyberon_english_train cyberon_english_test ; do
  data=./data/$part/mfcc39_pitch9
  mkdir -p $data
  for x in wav.scp text utt2spk ; do
    PYTHONIOENCODING=utf-8 python3 local/data/data_prep_cyberon_english.py $cyberon_english $part $x | sort -k1,1 -u > $data/$x || exit 1;
  done
  cat $data/utt2spk | utils/utt2spk_to_spk2utt.pl > $data/spk2utt || exit 1;
  utils/fix_data_dir.sh $data || exit 1;
done
