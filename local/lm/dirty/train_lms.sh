. ../path.sh
for x in guan water nie 20years laotsan water ; do
  ngram-count -text text_test/$x\.txt -lm text_test/$x\.lm -vocab text_test/vocab.txt -limit-vocab -order 4 
done
