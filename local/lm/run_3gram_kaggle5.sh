#/bin/bash
. path.sh
wfst=./data/wfst
dict=./data/wfst/dict
lang=./data/wfst/lang
tmp_lang=./data/wfst/local/lang
model_dir=exp/tri4a
LM=data/LM
text=data/text
#modify dict/lexicon.txt lexiconp.txt
#utils/prepare_lang.sh $dict "<UNK>" $tmp_lang $lang

#LM training
mkdir -p $LM/3gram
#ngram-count -text $text/mix.txt -lm $LM/3gram/mix.lm -vocab $lang/vocabs.txt -limit-vocab -order 3
#ngram -lm data/local/lm/3gram-mincount/lm_pr10.0 -vocab $lang/vocabs.txt -limit-vocab -write-lm $LM/3gram/ori_pr10.0.lm

for x in A B C ; do
    #ngram-count -text $text/kaggle123_$x.txt -lm $LM/3gram/kaggle123_$x.lm -vocab $lang/vocabs.txt -limit-vocab -order 3
    #ngram-count -text $text/kaggle1234_$x.txt -lm $LM/3gram/kaggle1234_$x.lm -vocab $lang/vocabs.txt -limit-vocab -order 3

    local/lm/mix_lm3_test.sh $LM/3gram/ori_pr10.0.lm $LM/3gram/kaggle123_$x.lm $LM/3gram/mix.lm \
      $LM/3gram/kaggle1234_$x.lm $text/kaggle4_$x.txt $LM/3gram/ori_$x\_10.0_kaggle1234.lm
done

for x in A B C ; do
  (
    lm=$LM/3gram/ori_$x\_10.0_kaggle1234.lm
    lang_test=./data/wfst/lang_test_pr10_$x\_kaggle5
    graph_dir=exp/tri4a/graph_pr10_$x\_kaggle5
    #G compilation and check L and G stochastic
    local/lm/wfst/format_data.sh $lm $lang $lang_test

    #compose HCLG(choice)
    utils/mkgraph.sh $lang_test $model_dir $graph_dir
  ) &
done
wait
