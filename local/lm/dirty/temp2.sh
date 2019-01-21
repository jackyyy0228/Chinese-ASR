for novel in journey_west red_mansion ; do
  for x in A B C ; do
    local/mix_lm3.sh text_test/ori.lm text_test/$novel.lm text_test/kaggle12_$x.lm text_test/$novel\_$x.txt LM/$novel\_$x\_kaggle12.lm $x\_lambda
  done
done
wait

