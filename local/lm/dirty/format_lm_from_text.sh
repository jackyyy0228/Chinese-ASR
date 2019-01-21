#!/bin/bash
. path.sh
set -euo pipefail

text_dir=lm_test/new_text
text_test=lm_test/text_test
LM=lm_test/LM
novel=$1

opencc -i $text_dir/$novel.txt -o $text_dir/$novel\_tra.txt 

PYTHONIOENCODING=utf-8 python3 local/kaggle/parse_text.py $text_dir/$novel\_tra.txt  $text_dir/$novel\_norm.txt 

ngram-count -text $text_dir/$novel\_norm.txt -lm $text_test/$novel\.lm -vocab $text_test/vocab.txt -limit-vocab -order 4 

ngram -lm $text_test/ori.lm -mix-lm $text_test/kaggle123_A.lm  -lambda 0.15 -mix-lm2 $text_test/$novel.lm \
  -mix-lambda2 0.8 -write-lm $LM/$novel\_A\.lm
ngram -lm $text_test/ori.lm -mix-lm $text_test/kaggle123_B.lm  -lambda 0.16 -mix-lm2 $text_test/$novel.lm \
  -mix-lambda2 0.35 -write-lm $LM/$novel\_B\.lm
ngram -lm $text_test/ori.lm -mix-lm $text_test/kaggle123_C.lm  -lambda 0.13 -mix-lm2 $text_test/$novel.lm \
  -mix-lambda2 0.35 -write-lm $LM/$novel\_C\.lm

for x in A B C ; do
  lm=$LM/$novel\_$x.lm
  lm_test/local/compile_lm.sh $lm &
done

wait
