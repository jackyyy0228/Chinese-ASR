#!/bin/bash
. ./local/data/corpus_path.sh

data=./data/Tl/mfcc39_pitch9
mkdir -p $data

for x in wav.scp utt2spk text; do
    PYTHONIOENCODING=utf-8 python3 local/data/data_prep_Tl.py $Tl $x | sort -k1,1 -u > $data/$x || exit 1;
done
cat $data/utt2spk | utils/utt2spk_to_spk2utt.pl > $data/spk2utt || exit 1;
utils/fix_data_dir.sh $data || exit 1;
