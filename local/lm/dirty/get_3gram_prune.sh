. path.sh
bash local/mix_lm3.sh lm_test/text_test/3gram_ori.lm lm_test/text_test/news.lm lm_test/text_test/all_novels_3gram.lm \
  text_test/kaggle123_A.txt text_test/3gram_mix.lm
ngram -lm lm_test/text_test/3gram_mix.lm -prune 0.0000001 -write-lm lm_test/text_test/3gram_mix_prune.lm
gzip lm_test/text_test/3gram_mix_prune.lm
bash local/format_data.sh lm_test/text_test/3gram_mix_prune.lm.gz data/lang_3small_mix_test
utils/mkgraph.sh data/lang_3small_mix_test exp/tri4a exp/tri4a/graph_mix
