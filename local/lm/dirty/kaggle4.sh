. ../path.sh
for novel in 20years guan laotsan nie water ; do
  ngram -lm text_test/ori.lm -mix-lm text_test/kaggle123_A.lm  -lambda 0.15 -mix-lm2 text_test/$novel.lm -mix-lambda2 0.8 -write-lm LM/$novel\_A\.lm
  ngram -lm text_test/ori.lm -mix-lm text_test/kaggle123_B.lm  -lambda 0.16 -mix-lm2 text_test/$novel.lm -mix-lambda2 0.35 -write-lm LM/$novel\_B\.lm
  ngram -lm text_test/ori.lm -mix-lm text_test/kaggle123_C.lm  -lambda 0.13 -mix-lm2 text_test/$novel.lm -mix-lambda2 0.35 -write-lm LM/$novel\_C\.lm
  for x in A B C ; do
    lm=LM/$novel\_$x.lm
    local/compile_lm.sh $lm &
  done
done
wait
