#!/bin/bash
. ./path.sh
. ./cmd.sh

chinese_tofel_corpus=/home/jacky/work/kgb/corpus/seg_chinese_tofel/
datadir=./data/chinese_tofel
wav_scp=$datadir/wav.scp

mkdir -p $datadir

find $chinese_tofel_corpus -iname "*.wav" | awk '{name = $0; gsub(".wav$","",name); 
gsub(".*/","",name); print(name " " $0)}' | sort #> $wav_scp || exit 1
exit

cat $wav_scp | awk '{print $1 " " $1}' > $datadir/utt2spk || exit 1;
cat $datadir/utt2spk |  utils/utt2spk_to_spk2utt.pl > $datadir/spk2utt || exit 1;

#extract spectrogram
#compute-spectrogram-feats --allow_downsample=true scp,p:$wav_scp ark,t:./data/spectrogram/chinese_tofel.ark

#extract mfcc+pitch
mfccdir=mfcc
x=chinese_tofel
steps/make_mfcc_pitch_online.sh --cmd "$train_cmd" --nj 8   $datadir exp/make_mfcc/$x $mfccdir || exit 1;
steps/compute_cmvn_stats.sh $datadir exp/make_mfcc/$x $mfccdir || exit 1;
