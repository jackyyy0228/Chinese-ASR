#!/bin/bash

novels="ori 20years nie guan laotsan water journey_west red_mansion 3kingdom beauty_n hunghuang lai_ho old_time one_gan lu_shun news"
#local/lm/generate_ori.sh
for novel in $novels ; do
  (
    txt=data/text/$novel.txt
    local/lm/text2Gfst.sh $txt 
  )&
done

wait

