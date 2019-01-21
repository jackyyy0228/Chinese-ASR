#!/bin/bash
. path.sh
for lang in lm_test/LM/* ; do
  (
    if [ -d $lang ]; then
      bos=`grep "<s>" $lang/words.txt | awk '{print $2}'`
      eos=`grep "</s>" $lang/words.txt | awk '{print $2}'`
      unk=`cat $lang/oov.int`

      cat $lang.lm  | \
        utils/map_arpa_lm.pl $lang/words.txt | \
        arpa-to-const-arpa --bos-symbol=$bos --eos-symbol=$eos \
        --unk-symbol=$unk - $lang/G.carpa
    fi
  )&
done
wait 
