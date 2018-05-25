#!/bin/bash
. ./local/data/corpus_path.sh

for part in cyberon_train cyberon_test ; do
  mkdir -p ./data/$part
  for x in wav.scp text utt2spk ; do
    PYTHONIOENCODING=utf-8 python3 local/data/data_prep_cyberon.py $cyberon_chinese $part $x | sort -k1,1 -u > data/$part/$x || exit 1;
  done
  cat data/$part/utt2spk | utils/utt2spk_to_spk2utt.pl > data/$part/spk2utt || exit 1;
done

