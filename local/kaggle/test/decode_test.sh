#!/bin/bash
all_wav_dir=$1
dir=$2
C_lang_dir=$3
nnet_dir=exp/nnet/tri4a_DFSMN_L_woiv_nnet_ali
nnet_dir=exp/nnet/tri4a_DFSMN_S_woiv

export nnet_dir=$nnet_dir
thread_num=100

asr() {
  wav_dir=$1
  rescore_lang=data/lang_4large_test
  use_gpu="no"

  if [ -f $wav_dir/rescore_lang ]; then
    rescore_lang=`cat $wav_dir/rescore_lang`
  fi
  
  if [ -f $wav_dir/use_gpu ]; then
    use_gpu=`cat $wav_dir/use_gpu`
  fi

  local/nnet/decode_from_wav.sh \
    --rescore_lang $rescore_lang \
    --fbank_nj 1 \
    --decode_nj 1 \
    --stage 1 \
    --use_gpu  $use_gpu \
    $wav_dir $nnet_dir $wav_dir > /dev/null || echo "error decoding $wav_dir"
  rm -r $wav_dir/data $wav_dir/final.mdl
  cat $wav_dir/output.txt >> $wav_dir/../output.txt
  echo "Done $wav_dir files"
}

export -f asr

mkdir -p $dir
startt=`date +%s`
python3 local/data/data_prep_wav_seperate.py $all_wav_dir $dir
python3 local/nnet/test/select_lm.py $dir $C_lang_dir

parallel -j $thread_num "asr {}" ::: $dir/*

endt=`date +%s`
runtime=$((endt-startt))
echo "Total time $runtime seconds"
echo "Total time $runtime seconds" > $dir/run_time
