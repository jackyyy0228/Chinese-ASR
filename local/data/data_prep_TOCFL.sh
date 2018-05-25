#!/bin/bash

. ./local/data/corpus_path.sh

mkdir -p ./data/TOCFL
for x in wav.scp text utt2spk ; do
  PYTHONIOENCODING=utf-8 python3 local/data/data_prep_TOCFL.py $TOCFL $x | sort -k1,1 -u > data/TOCFL/$x || exit 1;
done
cat data/TOCFL/utt2spk | utils/utt2spk_to_spk2utt.pl > data/TOCFL/spk2utt || exit 1;
utils/fix_data_dir.sh data/TOCFL || exit 1;
