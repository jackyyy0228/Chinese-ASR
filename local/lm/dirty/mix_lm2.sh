#!/bin/bash
. ../path.sh
lm1=$1
lm2=$2
test_text=$3
lm_out=$4
ngram -lm $lm1 -ppl $test_text -debug 2 > lm1.ppl
ngram -lm $lm2 -ppl $test_text -debug 2 > lm2.ppl
compute-best-mix lm1.ppl lm2.ppl > log
lambda=`python3 local/get_best_lambda.py log`
ngram -lm $lm1 -ppl $test_text -mix-lm $lm2 -lambda $lambda  -write-lm $lm_out
rm lm1.ppl lm2.ppl log
