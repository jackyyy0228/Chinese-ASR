#local/mix_lm2.sh text_test/ori.lm text_test/kaggle12_A.lm text_test/kaggle3_A.txt LM/A_kaggle12.lm
#local/mix_lm2.sh text_test/ori.lm text_test/kaggle12_B.lm text_test/kaggle3_B.txt LM/B_kaggle12.lm
#local/mix_lm2.sh text_test/ori.lm text_test/kaggle12_C.lm text_test/kaggle3_C.txt LM/C_kaggle12.lm

#local/mix_lm2_test.sh text_test/ori.lm text_test/kaggle12_A.lm text_test/kaggle123_A.lm text_test/kaggle3_A.txt LM/A.lm
#local/mix_lm2_test.sh text_test/ori.lm text_test/kaggle12_B.lm text_test/kaggle123_B.lm text_test/kaggle3_B.txt LM/B.lm
#local/mix_lm2_test.sh text_test/ori.lm text_test/kaggle12_C.lm text_test/kaggle123_C.lm text_test/kaggle3_C.txt LM/C.lm

for novel in 3kingdom journey_west red_mansion hunghuang ; do
  for x in A B C ; do
    local/mix_lm3.sh text_test/ori.lm text_test/$novel.lm text_test/kaggle12_$x.lm text_test/$novel\_$x.txt LM/$novel\_$x\_kaggle12.lm
    local/mix_lm3_test.sh text_test/ori.lm text_test/$novel.lm text_test/kaggle12_$x.lm text_test/kaggle123_$x.lm text_test/$novel\_$x.txt LM/$novel\_$x\.lm
  done
done
for x in LM/*.lm ; do
  (
    local/compile_lm.sh $x
  ) & 
done
wait
