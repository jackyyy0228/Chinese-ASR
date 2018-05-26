
#!bin/bash

mkdir -p $dictdir

cp $lexicon $dictdir/lexicon.txt
cat 'SIL' > $dictdir/silence_phone.txt
cat 'SIL' > $dictdir/optional_silence.txt
cat '' > $dictdir/extra_questions.txt
nonsilence_phones.txt
