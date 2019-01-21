#!/bin/bash
. path.sh
thread_num=100
#ngram ori -mix-lm nre lambda
test_lambda(){
  dir=$1
  Alm=$dir/A.lm
  orilm=/data/local/kgb/Chinese-ASR/lm_test/LM/C_kaggle12.lm
  echo $dir
  ngram-count -text $dir/A.txt -order 4 -lm $Alm 
  ngram -lm $orilm -ppl $dir/C.txt -debug 2 > $dir/ori.ppl
  ngram -lm $Alm -ppl $dir/C.txt -debug 2 > $dir/A.ppl
  compute-best-mix $dir/ori.ppl $dir/A.ppl > $dir/log
  python3 local/data/get_best_lambda.py $dir/log >> $dir/../best_lambda
}
export -f test_lambda

#PYTHOIOENCODING=utf-8 python3 local/data/test_lambda.py
parallel -j $thread_num "test_lambda {}" ::: lambda_test/*
python3 local/data/accumulate_lambda.py lambda_test/best_lambda

wait
