import os,sys
from opencc import OpenCC 
#remove brackets
def convert_to_8_digits(integer):
    x = str(integer)
    y = x
    for i in range(8-len(x)):
        y = '0' + y
    return y
def convert_to_zh(line):
    return converted

def main(corpus_path,file_type):
    openCC = OpenCC('s2t')  
    for root, dirs, files in os.walk(corpus_path, topdown=False):
        for name in files:
            if name.endswith('.flac'):
                wav_label = name.split('.')[0]
                wav_path = os.path.join(root,name)
                wav_path = os.path.abspath(wav_path)
                
                txt_path = wav_path.replace('audio','transcript/phaseII').replace('.flac','.txt')                
                if not os.path.isfile(txt_path):
                    continue

                if file_type == 'wav.scp':
                    flac_usage = 'flac -c -d -s {} |'.format(wav_path)
                    print(wav_label, flac_usage)
                else:
                    with open(txt_path,'r', encoding='utf-8') as f:
                        for line in f:
                            tokens = line.rstrip().split()
                            start,end = int(tokens[1]),int(tokens[2])
                            ct_s = convert_to_8_digits(start)
                            ct_e = convert_to_8_digits(end)
                            seg_label = tokens[0] + '_' + ct_s + '_' + ct_e
                            trans = ' '.join(tokens[4:])
                            for item in ['(',')','[',']','~']:
                                trans = trans.replace(item,'')
                            trans = openCC.convert(trans)

                            if file_type == 'utt2spk':
                                print(seg_label, seg_label)
                            elif file_type == 'text':
                                print(seg_label, trans)
                            elif file_type == 'segments':
                                print(seg_label, wav_label, start/1000, end/1000)
if __name__ == '__main__':
    corpus_path = sys.argv[1]
    file_type = sys.argv[2]
    main(corpus_path,file_type)
