#!/bin/bash
. path.sh

A_outputs=$1
C_lang_dir=$2
thread_num=15

mix_lm(){
  dir=$1
  Alm=$dir/A.lm
  orilm=`cat $dir/lm_path`
  echo $dir
  ngram-count -text $dir/A.txt -order 4 -lm $Alm 
  ngram -lm $orilm -mix-lm $Alm -lambda 0.6582 -write-lm $dir/rescore.lm -limit-vocab -vocab ./lm_test/text/vocab.txt
  mkdir -p $dir/rescore
  cp -r data/lang/* $dir/rescore
  cat $dir/rescore.lm | \
    arpa2fst --disambig-symbol=#0 \
             --read-symbol-table=$dir/rescore/words.txt - $dir/rescore/G.fst || exit 1;
  rm $dir/rescore.lm
  
  newlang=$dir/rescore
  phi=`grep -w '#0' $newlang/words.txt | awk '{print $2}'`
  fstprint $newlang/L_disambig.fst | awk '{if($4 != '$phi'){print;}}' | fstcompile | \
    fstdeterminizestar | fstrmsymbols $newlang/phones/disambig.int >$newlang/Ldet.fst || exit 1;
}

export -f mix_lm
mkdir -p $C_lang_dir

startt=`date +%s`
python3 local/kaggle/mix_LM_with_A.py $A_outputs $C_lang_dir kaggle4_lm

parallel -j $thread_num "mix_lm {}" ::: $C_lang_dir/*
endt=`date +%s`
runtime=$((endt-startt))
echo "Total time $runtime seconds"
