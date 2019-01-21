#/bin/bash
words=$1
out_fst=$2
text_fst=`dirname $2`
text_fst=$text_fst/text.fst

rm $text_fst

. path.sh

echo "
0 1 <one> <one>
1 2 <two> <two>
2 3 <three> <three>
3 4  <four> <four>" >> $text_fst

for i in 1 2 3 4  ; do
  cat $words | grep -v "<eps>" | grep -v "<one>" |\
    grep -v "<two>" | grep -v "<three>" |\
    grep -v "<four>" | grep -v "<s>" |\
    grep -v "</s>" | awk -v i=$i '{print i " " i " " $1 " " $1 }' >> $text_fst
done
echo 4 >> $text_fst


fstcompile --isymbols=$words --osymbols=$words \
   --keep_isymbols=false --keep_osymbols=false $text_fst | fstarcsort --sort_type=olabel  > $out_fst

