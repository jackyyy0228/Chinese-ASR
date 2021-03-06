#!/bin/bas1
A_dir=/data/local/kgb/corpus/kgb/semi-finals-2018/1/data/wav/A
B_dir=/data/local/kgb/corpus/kgb/semi-finals-2018/1/data/wav/B
C_dir=/data/local/kgb/corpus/kgb/semi-finals-2018/1/data/wav/C
A_dir=/data/local/kgb/Chinese-ASR/1213_simulate/wav/A
B_dir=/data/local/kgb/Chinese-ASR/1213_simulate/wav/B
C_dir=/data/local/kgb/Chinese-ASR/1213_simulate/wav/C

C_dir=/data/local/kgb/corpus/kgb/kaggle6/data/wav/C
iflytek_A=/data/local/kgb/Chinese-ASR/1110/iflytek_A
src_dir=./1110
decode_A=false

set -e
set -u
set -o pipefail
. path.sh

mkdir -p $src_dir

if $decode_A ; then

  #python3 local/kaggle/get_id_list.py $A_dir $src_dir/idx.json || exit 1;
  #bash local/kaggle/choose_lm2.sh $iflytek_A $src_dir/A_lm_test $src_dir/choose_lm || exit 1;
  
  #bash local/kaggle/check_sample_rate.sh $A_dir
  local/kaggle/decode_from_wav_seperate_by_lm.sh $A_dir $src_dir/A $src_dir/choose_lm A || exit 1;
  python3 local/kaggle/check_output_by_lm.py $src_dir/A
  #bash local/kaggle/mix_LM_with_A.sh $src_dir/A/output.txt $src_dir/C_lang
  #bash local/kaggle/test/decode_test.sh $test_C_dir $src_dir/C_test $src_dir/C_lang
else 
  #C:choices
  #bash local/kaggle/check_sample_rate.sh $C_dir || exit 1;
  local/kaggle/decode_from_wav_seperate_by_lm.sh $C_dir $src_dir/C_aishell_DFSMN_S_fine_tune $src_dir/choose_lm C || exit 1;
  python3 local/kaggle/check_output_by_lm.py $src_dir/C || exit 1;
  
  #B:question
  #bash local/kaggle/check_sample_rate.sh $B_dir
  #local/kaggle/decode_from_wav_seperate_by_lm.sh $B_dir $src_dir/B $src_dir/choose_lm B || exit 1;
  #python3 local/kaggle/check_output_by_lm.py $src_dir/B || exit 1;

  #python3 local/kaggle/merge_json.py $src_dir/A/output.txt $src_dir/B/output.txt $src_dir/C_n5/output.txt $src_dir/idx.json 5 $src_dir/result_kaldi_n.json

fi
