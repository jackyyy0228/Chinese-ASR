#!/bin/bash
corpus_dir=/data/local/kgb/corpus/esc_speech_noise
data_dir=data/esc_speech_noise
mkdir -p $data_dir
find -L $corpus_dir/ -iname "*.wav" | sort | xargs -I% basename % .wav | \
  awk -v "dir=$corpus_dir" '{printf "%s %s/%s.wav \n", $0, dir, $0}' > $data_dir/wav.scp
find -L $corpus_dir/ -iname "*.wav" | sort | xargs -I% basename % .wav | \
  awk -v "dir=$corpus_dir" '{printf "%s %s.wav \n", $0, $0}' > $data_dir/utt2spk
cat $data_dir/utt2spk | utils/utt2spk_to_spk2utt.pl > $data_dir/spk2utt || exit 1;
bash utils/data/get_reco2utt.sh $data_dir

utils/fix_data_dir.sh $data_dir || exit 1;
