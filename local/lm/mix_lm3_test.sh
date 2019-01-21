#!/bin/bash
. path.sh
lm1=$1
lm2=$2
lm3=$3
lm_replace=$4
test_text=$5
lm_out=$6
ngram -lm $lm1 -ppl $test_text -debug 2 > lm1.ppl
ngram -lm $lm2 -ppl $test_text -debug 2 > lm2.ppl
ngram -lm $lm3 -ppl $test_text -debug 2 > lm3.ppl
compute-best-mix lm1.ppl lm2.ppl lm3.ppl > log
lambda=`python3 local/lm/get_best_lambda.py log`
lambda2=`python3 local/lm/get_best_lambda2.py log`
ngram -lm $lm1 -ppl $test_text -mix-lm $lm_replace -lambda $lambda -mix-lm2 $lm2 -mix-lambda2 $lambda2 -write-lm $lm_out
rm lm1.ppl lm2.ppl lm3.ppl log
