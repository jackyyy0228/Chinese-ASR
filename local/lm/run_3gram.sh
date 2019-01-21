#/bin/bash
. path.sh
wfst=./data/wfst
dict=./data/wfst/dict
lang=./data/wfst/lang
tmp_lang=./data/wfst/local/lang
LM=data/LM
text=data/text
stage=1
#modify dict/lexicon.txt lexiconp.txt
#utils/prepare_lang.sh $dict "<UNK>" $tmp_lang $lang
if [ $stage -le 0 ] ; then
  #LM training
  mkdir -p $LM/3gram
  ngram-count -text $text/mix.txt -lm $LM/3gram/mix_novel.lm -vocab $lang/vocabs.txt -limit-vocab -order 3
  ngram-count -text $text/news.txt -lm $LM/3gram/news.lm -vocab $lang/vocabs.txt -limit-vocab -order 3 -prune 2e-7
  ngram -lm $LM/3gram/mix_novel.lm -mix-lm $LM/3gram/news.lm -lambda 0.9 -write-lm $LM/3gram/mix.lm

  ngram -lm data/local/lm/3gram-mincount/lm_pr10.0 -vocab $lang/vocabs.txt -limit-vocab -write-lm $LM/3gram/ori_pr10.0.lm

  for x in A B C ; do
      ngram-count -text $text/kaggle1234_$x.txt -lm $LM/3gram/kaggle1234_$x.lm -vocab $lang/vocabs.txt -limit-vocab -order 3
      ngram-count -text $text/kaggle12345_$x.txt -lm $LM/3gram/kaggle12345_$x.lm -vocab $lang/vocabs.txt -limit-vocab -order 3

      local/lm/mix_lm3_test.sh $LM/3gram/ori_pr10.0.lm $LM/3gram/kaggle1234_$x.lm $LM/3gram/mix.lm \
        $LM/3gram/kaggle12345_$x.lm $text/kaggle5_$x.txt $LM/3gram/ori_$x\_10.0_kaggle12345.lm
  done
fi
if [ $stage -le 1 ] ; then
  for x in A B C ; do
    (
      lm=$LM/3gram/ori_$x\_10.0_kaggle12345.lm
      lang_test=./data/wfst/lang_test_pr10_$x
      graph_dir=exp/tri4a/graph_pr10_$x
      model_dir=exp/tri4a
      model_dir=exp/aishell2/tri4_taiwanese
      graph_dir=$model_dir/graph_pr10_$x
      #G compilation and check L and G stochastic
      local/lm/wfst/format_data.sh $lm $lang $lang_test
      #compose HCLG(choice)
      rm -r $graph_dir
      utils/mkgraph.sh $lang_test $model_dir $graph_dir
    ) &
  done
  wait
fi
