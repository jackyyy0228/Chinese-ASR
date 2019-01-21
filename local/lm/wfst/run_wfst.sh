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
#PYTHONENCODING=utf-8 python3 local/lm/get_all_choices.py #> $wfst/kaggle12_C.txt
ngram-count -text $text/kaggle1234_C.txt -lm $LM/3gram/kaggle1234_C.lm -vocab $lang/vocabs.txt -limit-vocab -order 3
ngram-count -text $text/kaggle12345_C.txt -lm $LM/3gram/kaggle12345_C.lm -vocab $lang/vocabs.txt -limit-vocab -order 3
ngram-count -text $text/mix.txt -lm $LM/3gram/mix.lm -vocab $lang/vocabs.txt -limit-vocab -order 3


ngram -lm data/local/lm/3gram-mincount/lm_pr10.0 -vocab $lang/vocabs.txt -limit-vocab -write-lm $LM/3gram/ori_pr10.0.lm

local/lm/mix_lm3_test.sh $LM/3gram/ori_pr10.0.lm $LM/3gram/kaggle1234_C.lm $LM/3gram/mix.lm \
  $LM/3gram/kaggle12345_C.lm $text/kaggle5_C.txt $LM/3gram/ori_C_10.0.lm  

(
  lm=$LM/3gram/ori_C_10.0.lm
  lang_test=./data/wfst/lang_test_pr10_C
  graph_dir=exp/tri4a/graph_wfst_pr10_C
  #G compilation and check L and G stochastic
  local/kaggle/wfst/format_data.sh $lm $lang $lang_test
  if false ; then
    #Choice fst compilation
    local/kaggle/wfst/generate_choice_fst.sh $lang_test/words.txt $lang_test/choice.fst


    #compose choice.fst and G.fst
    mv $lang_test/G.fst $lang_test/G_head.fst
    fsttablecompose $lang_test/G_head.fst $lang_test/choice.fst  | \
      fstdeterminizestar --use-log=true | \
      fstminimizeencoded  > $lang_test/G.fst
  fi

  #compose HCLG(choice)
  utils/mkgraph.sh $lang_test $model_dir $graph_dir
) 

wait



