#!/bin/bash
nnet_dir=exp/nnet/tri4a_DFSMN_S_woiv_aug_ori
#nnet_dir=exp/nnet/tri4a_DFSMN_S_woiv
mode=4 # mode for lmrescoring
C_lang_dir=X
choose_lm_file=
graph=exp/tri4a/graph_wfst 
graph=exp/tri4a/graph_pr10_A 
rescore_arpa=false

. ./utils/parse_options.sh

all_wav_dir=$1
dir=$2

export nnet_dir=$nnet_dir
export mode=$mode
export graph=$graph
export rescore_arpa=$rescore_arpa
thread_num=80

asr() {
  wav_dir=$1
  rescore_lang=data/lang_4large_test
  use_gpu="no"

  if [ -f $wav_dir/rescore_lang ]; then
    rescore_lang=`cat $wav_dir/rescore_lang`
  fi
  
  if [ -f $wav_dir/rescore_arpa ]; then
    rescore_arpa=`cat $wav_dir/rescore_arpa`
  fi
  if [ -f $wav_dir/mode ]; then
    mode=`cat $wav_dir/mode`
  fi
  
  #if [ -f $wav_dir/use_gpu ]; then
  #  use_gpu=`cat $wav_dir/use_gpu`
  #fi
  local/kaggle/decode_from_wav.sh \
    --choose_lm $choose_lm \
    --rescore_lang $rescore_lang \
    --fbank_nj 1 --mode $mode \
    --rescore_arpa $rescore_arpa \
    --decode_nj 1 \
    --stage 1 \
    --graph $graph \
    --use_gpu  $use_gpu \
    $wav_dir $nnet_dir $wav_dir > $wav_dir/log || echo "error decoding $wav_dir"
  rm -r $wav_dir/data 
  rm -r $wav_dir/final.mdl
  rm $wav_dir/decode*/lat.1.gz
  cat $wav_dir/output.txt >> $wav_dir/../output.txt
  if $choose_lm ; then
    cat $wav_dir/lm >> $wav_dir/../../kaggle_simulate_lm
  fi
  echo "Done $wav_dir files"
}

export -f asr

mkdir -p $dir
startt=`date +%s`
python3 local/kaggle/data_prep_wav_seperate.py $all_wav_dir $dir

if [ -z $choose_lm_file ] ; then
  # if choose_lm_file is not assigned
  choose_lm=true
else
  choose_lm=false
  echo "Selecting LM"
  python3 local/kaggle/select_lm.py --src_dir $dir --C_lang_dir  $C_lang_dir --choose_lm $choose_lm_file
fi
choose_lm=false
export choose_lm=$choose_lm

parallel -j $thread_num "asr {}" ::: $dir/*

endt=`date +%s`
runtime=$((endt-startt))
echo "Total time $runtime seconds"
echo "Total time $runtime seconds" > $dir/run_time
