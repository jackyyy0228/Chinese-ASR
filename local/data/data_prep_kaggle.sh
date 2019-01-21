#!/bin/bash

kaggle=/data/local/kgb/corpus/kgb/kaggle6 

for typ in A B C ; do
  data=./data/kaggle6/$typ/fbank
  mkdir -p $data
  for x in wav.scp utt2spk text ; do
    PYTHONIOENCODING=utf-8 python3 local/data/data_prep_kaggle.py $kaggle $x $typ data/lang/words.txt | sort -k1,1 -u > $data/$x || exit 1;
  done
  cat $data/utt2spk | utils/utt2spk_to_spk2utt.pl > $data/spk2utt || exit 1;
  utils/fix_data_dir.sh $data || exit 1;
done
