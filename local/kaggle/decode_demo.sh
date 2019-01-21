#!/bin/bash
cd /data/local/kgb/Chinese-ASR
nnet_dir=exp/nnet/tri4a_DFSMN_S_woiv_aug_ori
mode=4 # mode for lmrescoring

. ./utils/parse_options.sh

wavA=$1
wavB=$2


export nnet_dir=$nnet_dir
export mode=$mode
export graph=$graph
export rescore_arpa=$rescore_arpa

asr() {
  wav=$1
  typ=$2
  tmpdir=$3

  wav_dir=$tmpdir/$typ
  data_dir=$wav_dir/data

  mkdir -p $data_dir

  name=`basename $wav`
  
  echo $name $wav > $data_dir/wav.scp
  echo $name $name > $data_dir/utt2spk
  echo $name $name > $data_dir/spk2utt

  rescore_lang=data/LM/ori_$typ
  graph=exp/tri4a/graph_pr10_$typ
  
  local/kaggle/decode_from_wav.sh \
    --rescore true \
    --rescore_lang $rescore_lang \
    --fbank_nj 1 --mode $mode \
    --decode_nj 1 \
    --stage 1 \
    --graph $graph \
    $wav_dir $nnet_dir $wav_dir > $wav_dir/log || echo "error decoding $wav_dir"

  cp $wav_dir/data/wav.scp $wav_dir
  rm -r $wav_dir/data
  rm -r $wav_dir/final.mdl

  output=`cat $wav_dir/output.txt | cut -d' ' -f2- `
  echo $typ $output
}

tmpdir=`mktemp -d`


( asr $wavA A $tmpdir ) &
( asr $wavB B $tmpdir ) &


wait

rm -r $tmpdir
