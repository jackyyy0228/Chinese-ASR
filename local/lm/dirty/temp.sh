for novel in 3kingdom ; do
  for x in A B C ; do
    local/mix_lm3.sh text_test/ori.lm text_test/$novel.lm text_test/kaggle12_$x.lm text_test/$novel\_$x.txt LM/$novel\_$x\_kaggle12.lm
    local/mix_lm3_test.sh text_test/ori.lm text_test/$novel.lm text_test/kaggle12_$x.lm text_test/kaggle123_$x.lm text_test/$novel\_$x.txt LM/$novel\_$x\.lm
    local/compile_lm.sh LM/$novel\_$x\_kaggle12.lm &
    local/compile_lm.sh LM/$novel\_$x\.lm &
  done
done
wait
