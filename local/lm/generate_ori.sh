#/bin/bash
. path.sh
LM=data/LM
text=data/text
lang=data/wfst/lang
vocab=$lang/vocabs.txt
words=$lang/words.txt 
ngram -lm data/wfst/LM/ori_4gram.lm -vocab $vocab -limit-vocab -write-lm $LM/ori.lm
for x in A B C; do
  (
    ngram-count -text $text/kaggle1234_$x.txt -lm $LM/kaggle1234_$x.lm -vocab $vocab -limit-vocab -order 4
    ngram-count -text $text/kaggle12345_$x.txt -lm $LM/kaggle12345_$x.lm -vocab $vocab -limit-vocab -order 4
  ) &
done
wait
for x in A B C; do
    local/lm/mix_lm2_test.sh $LM/ori.lm $LM/kaggle1234_$x.lm $LM/kaggle12345_$x.lm $text/kaggle5_$x.txt $LM/ori_$x.lm
done
