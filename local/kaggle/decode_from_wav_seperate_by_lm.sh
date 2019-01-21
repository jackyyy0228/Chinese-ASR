#!/bin/bash
nnet_dir=exp/nnet/tri4a_DFSMN_S_woiv_aug_ori
nnet_dir=exp/nnet/aishell2/tri4a_DFSMN_M_aug_ori_2
nnet_dir=exp/nnet/aishell2/tri4a_DFSMN_S_aug_ori_fine_tuned

#nnet_dir=exp/nnet/tri4a_DFSMN_S_woiv
mode=4 # mode for lmrescoring
C_lang_dir=X
rescore_arpa=false
beam=13
max_active=7000
lattice_beam=8.0
num_threads=3
n_best=1
max_nj=10
. ./utils/parse_options.sh

all_wav_dir=$1
dir=$2
choose_lm_file=$3
type_qa=$4

graph=exp/tri4a/graph_pr10_$type_qa
graph=exp/aishell2/tri4_taiwanese/graph_pr10_$type_qa

if [ $type_qa == A ]; then
  max_nj=15
fi

export nnet_dir=$nnet_dir
export mode=$mode
export graph=$graph
export rescore_arpa=$rescore_arpa
export beam=$beam
export max_active=$max_active
asr() {
  wav_dir=$1
  rescore_lang=data/lang_4large_test
  use_gpu="no"

  if [ -f $wav_dir/rescore_lang ]; then
    rescore_lang=`cat $wav_dir/rescore_lang`
  fi
  
  if [ -f $wav_dir/mode ]; then
    mode=`cat $wav_dir/mode`
  fi
  nj=1
  if [ -f $wav_dir/nj ]; then
    nj=`cat $wav_dir/nj`
  fi
  
  #if [ -f $wav_dir/use_gpu ]; then
  #  use_gpu=`cat $wav_dir/use_gpu`
  #fi
  #decode 3small
  local/kaggle/decode_from_wav.sh \
    --rescore  false \
    --rescore_lang $rescore_lang \
    --fbank_nj $nj --mode $mode \
    --rescore_arpa $rescore_arpa \
    --decode_nj $nj \
    --stage 1 \
    --beam $beam --max_active $max_active \
    --lattice_beam $lattice_beam \
    --n_best $n_best \
    --graph $graph \
    --num_threads $num_threads \
    --use_gpu  $use_gpu \
    $wav_dir $nnet_dir $wav_dir > $wav_dir/log || echo "error decoding $wav_dir"
  quota=$wav_dir/../quota 
  q=`cat $quota`
  nj=`cat $wav_dir/nj`
  q2=$((q-(nj*3/4)))
  echo $q2 > $quota

  local/kaggle/decode_from_wav.sh \
    --rescore true \
    --rescore_lang $rescore_lang \
    --fbank_nj $nj --mode $mode \
    --rescore_arpa $rescore_arpa \
    --decode_nj $nj \
    --stage 3 \
    --beam $beam --max_active $max_active \
    --lattice_beam $lattice_beam \
    --graph $graph \
    --n_best $n_best \
    --num_threads $num_threads \
    --use_gpu  $use_gpu \
    $wav_dir $nnet_dir $wav_dir > $wav_dir/log || echo "error decoding $wav_dir"
  
  q=`cat $quota`
  nj=`cat $wav_dir/nj`
  q2=$((q+(nj*3/4)-nj))
  echo $q2 > $quota
  
  cp $wav_dir/data/wav.scp $wav_dir
  rm -r $wav_dir/data
  rm -r $wav_dir/final.mdl
  #rm $wav_dir/decode*/lat.*
  cat $wav_dir/output.txt >> $wav_dir/../output.txt
  
  echo "Done $wav_dir."
}

export -f asr

mkdir -p $dir
startt=`date +%s`
python3 local/kaggle/data_prep_wav_seperate_by_lm.py $all_wav_dir $dir $choose_lm_file $type_qa
echo 0 > $dir/quota

quota=$dir/quota
all_lms=`cat $dir/all_lms`

for lm in $all_lms; do
  q=`cat $quota`
  nj=`cat $dir/$lm/nj`
  q2=$((q+nj))
  while [[ $q2 -gt $max_nj ]]; do
    # wait only for first job
    sleep 1
    q=`cat $quota`
    nj=`cat $dir/$lm/nj`
    q2=$((q+nj))
  done
  #add quota
  q=`cat $quota`
  nj=`cat $dir/$lm/nj`
  q2=$((q+nj))
  echo $q2 > $quota
  (
    echo "start $lm $nj $q2"
    asr $dir/$lm
    #substact quota 
  ) & 

done

wait
endt=`date +%s`
runtime=$((endt-startt))
echo "Total time $runtime seconds"
echo "Total time $runtime seconds" > $dir/run_time
