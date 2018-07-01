#!/bin/bash
## Decode all the *.wav from specified directory

. ./path.sh
. ./cmd.sh


if [ $# != 2 ]; then
  echo " Usage : decode_wav.sh <wav_dir> <decode_dir> "
fi

stage=0
nj=8

. ./utils/parse_options.sh

lang=data/lang
dir=exp/nnet3/tdnn_lstm_no_eng_nnet_align
wav_dir=$1
decodedir=$2

mkdir -p $decodedir

ivector_extractor=exp/nnet3/extractor
name=`basename $decodedir`

datadir=$decodedir/data
data_np_dir=$decodedir/data_no_pitch
mfccpitchdir=$decodedir/mfcc_pitch
mfccdir=$decodedir/mfcc
ivectordir=$decodedir/ivector
expdir=$decodedir/exp
gmm_dir=exp/tri4a

mkdir -p $datadir $data_np_dir $mfccdir $mfccpitchdir $ivectordir $expdir 

if [ $stage -le 0 ]; then
  startt=`date +%s`
  local/data/data_prep_wav.sh $wav_dir $datadir 
  steps/make_mfcc_pitch_online.sh --cmd "$train_cmd" --nj $nj --mfcc-config conf/mfcc_hires.conf --name $name \
    $datadir $expdir $mfccpitchdir || exit 1;
  steps/compute_cmvn_stats.sh --name $name $datadir $expdir $mfccpitchdir || exit 1;

  utils/fix_data_dir.sh $datadir
  
  # create MFCC data dir without pitch to extract iVector
  

  utils/data/limit_feature_dim.sh 0:39 $datadir $data_np_dir || exit 1;
  steps/compute_cmvn_stats.sh --name $name $data_np_dir $expdir/$name\_np $mfccdir || exit 1;

  utils/fix_data_dir.sh $data_np_dir
  
  endt=`date +%s`
  runtime=$((endt-startt))
  echo "Time of Making mfcc: $runtime"
fi

if [ $stage -le 1 ]; then
  startt=`date +%s`
  rm -f exp/nnet3/.error 2>/dev/null
  steps/online/nnet2/extract_ivectors_online.sh --cmd "$train_cmd" --nj $nj \
    $data_np_dir $ivector_extractor $ivectordir || touch exp/nnet3/.error
  endt=`date +%s`
  runtime=$((endt-startt))
  echo "Time of extracting ivectors: $runtime"
  [ -f exp/nnet3/.error ] && echo "$0: error extracting iVectors." && exit 1;
fi

if [ $stage -le 2 ]; then
  rm $dir/.error 2>/dev/null || true
  graph_dir=$gmm_dir/graph                                     
  
  startt=`date +%s`
  steps/nnet3/decode_looped.sh \
    --frames-per-chunk 30 \
    --nj 8 --cmd "$decode_cmd" \
    --online-ivector-dir $ivectordir \
    --stage 3 \
    $graph_dir $datadir ${dir}/decode_looped_3small_$name || exit 1
  
  endt=`date +%s`
  runtime=$((endt-startt))
  echo "Decode_loop time of $affix: $runtime"
  
  startt=`date +%s`
  steps/lmrescore.sh --cmd "$decode_cmd" data/lang_3{small,mid}_test \
    $datadir ${dir}/decode_looped_3{small,mid}_$name || exit 1
  
  endt=`date +%s`
  runtime=$((endt-startt))
  echo "Decode_loop rescoring time of : $runtime"
  
  startt=`date +%s`
  steps/lmrescore.sh --cmd "$decode_cmd" data/lang_{3mid,4large}_test \
    $datadir ${dir}/decode_looped_{3mid,4large}_$name || exit 1
  
  endt=`date +%s`
  runtime=$((endt-startt))
  echo "Decode_loop rescoring time of : $runtime"
fi

