#!/bin/bash
#

if [ -f ./path.sh ]; then . ./path.sh; fi

silprob=0.5

lm_type=4gram-mincount
dir=data/local/lm
add_ABCD=true

. ./utils/parse_options.sh

arpa_lm=$dir/$lm_type/lm_unpruned.gz
lang_test=data/lang_$lm_type\_test

if [ $add_ABCD = true ] ; then
  arpa_lm=$dir/$lm_type/lm_unpruned_ABCD.gz
  lang_test=data/lang_$lm_type\_ABCD_test
fi

[ ! -f $arpa_lm ] && echo No such file $arpa_lm && exit 1;


rm -r $lang_test
cp -r data/lang $lang_test

gunzip -c "$arpa_lm" | \
  arpa2fst --disambig-symbol=#0 \
           --read-symbol-table=$lang_test/words.txt - $lang_test/G.fst


echo  "Checking how stochastic G is (the first of these numbers should be small):"
fstisstochastic $lang_test/G.fst

## Check lexicon.
## just have a look and make sure it seems sane.
echo "First few lines of lexicon FST:"
fstprint   --isymbols=data/lang/phones.txt --osymbols=data/lang/words.txt data/lang/L.fst  | head

echo Performing further checks

# Checking that G.fst is determinizable.
fstdeterminize $lang_test/G.fst /dev/null || echo Error determinizing G.

# Checking that L_disambig.fst is determinizable.
fstdeterminize $lang_test/L_disambig.fst /dev/null || echo Error determinizing L.

# Checking that disambiguated lexicon times G is determinizable
# Note: we do this with fstdeterminizestar not fstdeterminize, as
# fstdeterminize was taking forever (presumbaly relates to a bug
# in this version of OpenFst that makes determinization slow for
# some case).
fsttablecompose $lang_test/L_disambig.fst $lang_test/G.fst | \
   fstdeterminizestar >/dev/null || echo Error

# Checking that LG is stochastic:
fsttablecompose data/lang/L_disambig.fst $lang_test/G.fst | \
   fstisstochastic || echo LG is not stochastic


echo format_data succeeded.
