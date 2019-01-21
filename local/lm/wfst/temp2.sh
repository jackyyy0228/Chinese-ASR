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

#ngram -lm data/local/lm/3gram-mincount/lm_pr10.0 -vocab $lang/vocabs.txt -limit-vocab -write-lm $LM/3gram/ori_pr10.0.lm

local/lm/mix_lm3_test.sh $LM/3gram/ori_pr10.0.lm $LM/3gram/kaggle123_C.lm $LM/3gram/mix.lm \
  $LM/3gram/kaggle1234_C.lm $text/kaggle4_C.txt $LM/3gram/ori_C_10.0.lm  


lm=$LM/3gram/ori_C_10.0.lm
lang_test=./data/wfst/lang_test_pr10_C
graph_dir=exp/tri4a/graph_pr10_C
#G compilation and check L and G stochastic
local/kaggle/wfst/format_data.sh $lm $lang $lang_test

#compose HCLG(choice)
utils/mkgraph.sh $lang_test $model_dir $graph_dir



