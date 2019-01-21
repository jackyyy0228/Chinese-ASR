#!/bin/bash
. path.sh
x=$1
dir=${x::-3}

mkdir -p $dir
cp -r data/lang/* $dir

ngram -lm $x -vocab lm_test/text/vocab.txt -limit-vocab -write-lm $x

cat $x | \
  arpa2fst --disambig-symbol=#0 \
           --read-symbol-table=$dir/words.txt - $dir/G.fst || exit 1;
## compile Ldet.fst
newlang=$dir
phi=`grep -w '#0' $newlang/words.txt | awk '{print $2}'`
fstprint $newlang/L_disambig.fst | awk '{if($4 != '$phi'){print;}}' | fstcompile | \
  fstdeterminizestar | fstrmsymbols $newlang/phones/disambig.int >$newlang/Ldet.fst || exit 1;

##transform to G.carpa
bos=`grep "<s>" $dir/words.txt | awk '{print $2}'`
eos=`grep "</s>" $dir/words.txt | awk '{print $2}'`
unk=`cat $dir/oov.int`

cat $x  | \
  utils/map_arpa_lm.pl $dir/words.txt | \
  arpa-to-const-arpa --bos-symbol=$bos --eos-symbol=$eos \
  --unk-symbol=$unk - $dir/G.carpa
