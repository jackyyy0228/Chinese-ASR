#!/bin/bash
A_dir=/data/local/kgb/Chinese-ASR/1213_simulate/wav/A
B_dir=/data/local/kgb/Chinese-ASR/1213_simulate/wav/B
C_dir=/data/local/kgb/Chinese-ASR/1213_simulate/wav/C
#B_dir=/data/local/kgb/corpus/kgb/kaggle1/data/wav/B
#C_dir=/data/local/kgb/corpus/kgb/kaggle1/data/wav/C
#test_C_dir=/data/local/kgb/corpus/kgb/kaggle3/data/wav/C
#iflytek_A=/data/local/kgb/Chinese-ASR/0622/iflytek_A
src_dir=./1213_simulate
decode_A=true

set -e
set -u
set -o pipefail
. path.sh

mkdir -p $src_dir

if $decode_A ; then
  python3 local/kaggle/get_id_list.py $A_dir $src_dir/idx.json || exit 1;
  
  #bash local/kaggle/check_sample_rate.sh $A_dir
  local/kaggle/decode_from_wav_seperate.sh $A_dir $src_dir/A || exit 1; #select lm itself
  
  python3 local/kaggle/check_output.py $src_dir/A
  #bash local/kaggle/mix_LM_with_A.sh $src_dir/A/output.txt $src_dir/C_lang
  #bash local/kaggle/test/decode_test.sh $test_C_dir $src_dir/C_test $src_dir/C_lang
else 
  #C:choices 把choose lm comment掉
  bash local/kaggle/check_sample_rate.sh $C_dir || exit 1;
  local/kaggle/decode_from_wav_seperate.sh --choose_lm_file $src_dir/kaggle_simulate_lm $C_dir $src_dir/C  || exit 1;
  python3 local/kaggle/check_output.py $src_dir/C || exit 1;
  #B:question
  bash local/kaggle/check_sample_rate.sh $B_dir
  local/kaggle/decode_from_wav_seperate.sh --choose_lm_file $src_dir/kaggle_simulate_lm $B_dir $src_dir/B || exit 1;
  python3 local/kaggle/check_output.py $src_dir/B || exit 1;

  python3 local/kaggle/merge_json.py $src_dir/A/output.txt $src_dir/B/output.txt $src_dir/C/output.txt $src_dir/idx.json $src_dir/result_kaldi.json
fi

