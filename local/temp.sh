#!/bin/bash
. ./path.sh
. ./cmd.sh


lm_type=4gram-mincount
dir=data/local/lm

arpa_lm=$dir/$lm_type/lm_unpruned.gz
arpa_lm_unzip=$dir/$lm_type/lm_unpruned

arpa_ABCD=$dir/$lm_type/lm_unpruned_ABCD
gunzip $arpa_lm

PYTHONIOENCODING=utf-8 python3 local/add_ABCD.py $arpa_lm_unzip $arpa_ABCD
gzip $arpa_lm_unzip
gzip $arpa_ABCD
