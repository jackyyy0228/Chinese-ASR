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

ngram -lm data/local/lm/3gram-mincount/lm_pr20.0 -vocab $lang/vocabs.txt -limit-vocab -write-lm $LM/3gram/ori_pr20.0.lm
ngram -lm data/local/lm/3gram-mincount/lm_pr30.0 -vocab $lang/vocabs.txt -limit-vocab -write-lm $LM/3gram/ori_pr30.0.lm

local/lm/mix_lm3_test.sh $LM/3gram/ori_pr20.0.lm $LM/3gram/kaggle123_C.lm $LM/3gram/mix.lm \
  $LM/3gram/kaggle1234_C.lm $text/kaggle4_C.txt $LM/3gram/ori_C_20.0.lm  
local/lm/mix_lm3_test.sh $LM/3gram/ori_pr30.0.lm $LM/3gram/kaggle123_C.lm $LM/3gram/mix.lm \
  $LM/3gram/kaggle1234_C.lm $text/kaggle4_C.txt $LM/3gram/ori_C_30.0.lm  

(
  lm=$LM/3gram/ori_C_20.0.lm
  lang_test=./data/wfst/lang_test_pr20_C
  graph_dir=exp/tri4a/graph_wfst_pr20_C
  #G compilation and check L and G stochastic
  local/kaggle/wfst/format_data.sh $lm $lang $lang_test
  #Choice fst compilation
  local/kaggle/wfst/generate_choice_fst.sh $lang_test/words.txt $lang_test/choice.fst


  #compose choice.fst and G.fst
  mv $lang_test/G.fst $lang_test/G_head.fst
  fsttablecompose $lang_test/G_head.fst $lang_test/choice.fst  | \
    fstdeterminizestar --use-log=true | \
    fstminimizeencoded  > $lang_test/G.fst

  #compose HCLG(choice)
  utils/mkgraph.sh $lang_test $model_dir $graph_dir
) &

(
  lm=$LM/3gram/ori_C_30.0.lm
  lang_test=./data/wfst/lang_test_pr30_C
  graph_dir=exp/tri4a/graph_wfst_pr30_C
  #G compilation and check L and G stochastic
  local/kaggle/wfst/format_data.sh $lm $lang $lang_test
  #Choice fst compilation
  local/kaggle/wfst/generate_choice_fst.sh $lang_test/words.txt $lang_test/choice.fst


  #compose choice.fst and G.fst
  mv $lang_test/G.fst $lang_test/G_head.fst
  fsttablecompose $lang_test/G_head.fst $lang_test/choice.fst  | \
    fstdeterminizestar --use-log=true | \
    fstminimizeencoded  > $lang_test/G.fst

  #compose HCLG(choice)
  utils/mkgraph.sh $lang_test $model_dir $graph_dir
) &
wait



