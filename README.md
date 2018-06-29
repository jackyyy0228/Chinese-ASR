# Chinese-ASR
Chinese-ASR built on kaldi

## Dependencies:
Opencc: convert simplified Chinese to traditional Chinese

https://github.com/yichen0831/opencc-python

jeiba zh version : Traditional Chinese word segmentation tool:

https://l.facebook.com/l.php?u=https%3A%2F%2Fgithub.com%2Fldkrsi%2Fjieba-zh_TW&h=ATPhhi1b7UYw84pPzgAz4MDbn3MRo7oFLAuhBLW8geUqHF0O1YZDnXsNh5qe7tQVWGQ5uaocYvuV-UsuvALNeN3LRaq68ACLMfbWE2RivhiCHoyjcFtNTVy6XG0sh5MJTp5tYEZm0xA

## Usage

1.modify kaldi path in path.sh 

2.modify corpus path in local/data/corpus_path.sh

3.Install sequitar(G2P), sox, kaldi_lm in kaldi/tools/

4.bash run.sh

## Experiment

| Ｍodel        | TOCFL(CER%)     | Cyberon_Chinese_test(CER%)  |
| ------------- |:--------------:| ----------------------------:|
| mono0a        | 97.76           |    100.71                   |
| tri1          | 50.55           |    63.64                    |
| tri2          | 56.62           |    46.65                    |
| tri3          | 34.78           |    46.78                    |
| tri4          | 37.02           |    34.02                    | 
| tri5          | 65.60           |    49.96                    |
| tdnn_lstm1     | 18.30           |    24.82                    | 
| tdnn_lstm(realign)     | 15.88           |    22.24                    | 
