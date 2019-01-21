#/bin/bash
. path.sh
lm_dir=data/LM
lang=data/wfst/lang
choice_fst=data/wfst/lang_test/choice.fst
words=$lang/words.txt 

for x in $lm_dir/*C ; do
  if [ -d $x ]; then
    (
      ngram -lm $x.lm -prune 2e-7 -write-lm $x\_pruned.lm
      xdir=$x\_pruned
      xlm=$x\_pruned.lm
      cp -r $lang $xdir
      cat $xlm | arpa2fst --disambig-symbol=#0 \
        --read-symbol-table=$words -  | fstarcsort --sort_type=olabel > $xdir/G.fst

      ## compile Ldet.fst
      phi=`grep -w '#0' $words | awk '{print $2}'`
      
      fstprint $xdir/L_disambig.fst | awk '{if($4 != '$phi'){print;}}' | fstcompile | \
        fstdeterminizestar | fstrmsymbols $xdir/phones/disambig.int > $xdir/Ldet.fst || exit 1;
      
      mv $xdir/G.fst $xdir/G_head.fst
      fsttablecompose $xdir/G_head.fst $choice_fst  | \
        fstdeterminizestar --use-log=true | \
        fstminimizeencoded  > $xdir/G.fst
    ) &
  fi
done

wait


