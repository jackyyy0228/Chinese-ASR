#/bin/bash
text=$1
LM=data/LM
basename=`basename $text`
name=${basename::-4}
lm=$LM/$name.lm
lang=data/wfst/lang
vocab=$lang/vocabs.txt
words=$lang/words.txt 
choice_fst=data/wfst/lang_test/choice.fst
ori_lm=data/wfst/LM/ori_4gram.lm
Alm=data/LM/kaggle12345_A.lm
Blm=data/LM/kaggle12345_B.lm
Clm=data/LM/kaggle12345_C.lm

. path.sh
. ./utils/parse_options.sh 


if [ $name == "ori" ]; then
  echo "ori"
  mv $LM/ori_C.lm $LM/ori_C2.lm
  ngram -lm $LM/ori_C2.lm -prune 2e-7 -write-lm $LM/ori_C.lm
  rm $LM/ori_C2.lm
else 
  ngram-count -text $text -lm $lm -vocab $vocab -limit-vocab -order 4 
  ngram -lm $ori_lm -mix-lm $Alm  -lambda 0.15 -mix-lm2 $lm -mix-lambda2 0.8 -write-lm $LM/$name\_A.lm
  ngram -lm $ori_lm -mix-lm $Blm  -lambda 0.16 -mix-lm2 $lm -mix-lambda2 0.35 -write-lm $LM/$name\_B.lm
  ngram -lm $ori_lm -mix-lm $Clm  -lambda 0.13 -mix-lm2 $lm -mix-lambda2 0.35 -prune 2e-7 -write-lm $LM/$name\_C.lm
fi
for x in C; do 
  xdir=$LM/$name\_$x
  xlm=$LM/$name\_$x.lm
  cp -r $lang $xdir
  cat $xlm | arpa2fst --disambig-symbol=#0 \
    --read-symbol-table=$words -  | fstarcsort --sort_type=olabel > $xdir/G.fst

  ## compile Ldet.fst
  phi=`grep -w '#0' $words | awk '{print $2}'`
  
  fstprint $xdir/L_disambig.fst | awk '{if($4 != '$phi'){print;}}' | fstcompile | \
    fstdeterminizestar | fstrmsymbols $xdir/phones/disambig.int > $xdir/Ldet.fst || exit 1;
  
  if [ $x == C ]; then
    mv $xdir/G.fst $xdir/G_head.fst
    fsttablecompose $xdir/G_head.fst $choice_fst  | \
      fstdeterminizestar --use-log=true | \
      fstminimizeencoded  > $xdir/G.fst
  fi
  ##transform to G.carpa
  if false; then
    bos=`grep "<s>" $words.txt | awk '{print $2}'`
    eos=`grep "</s>" $words.txt | awk '{print $2}'`
    unk=`cat $dir/oov.int`

    cat $x  | \
      utils/map_arpa_lm.pl $xdir/words.txt | \
      arpa-to-const-arpa --bos-symbol=$bos --eos-symbol=$eos \
      --unk-symbol=$unk - $xdir/G.carpa
  fi
done
