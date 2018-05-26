import os,sys

def main(corpus_path,file_type):
    for root, dirs, files in os.walk(os.path.join(corpus_path,'syl'), topdown=False):
        for name in files:
            if name.endswith('.txt'):
                txt_path = os.path.join(root,name)
                with open(txt_path,'r') as f:
                    for line in f:
                        tokens = line.rstrip().split()
                        wav_file, trans = tokens[-1],tokens[1]

                        wav_label = wav_file.split('.')[0]
                        trans = ' '.join(list(trans))
                        
                        spk = wav_file.split('_')[0]
                        wav_path = os.path.join(corpus_path,'Wav/{}/{}'.format(spk,wav_file))
                        wav_path = os.path.abspath(wav_path)
                        if file_type == 'wav.scp':
                            print(wav_label, wav_path)
                        elif file_type == 'utt2spk':
                            print(wav_label, spk)
                        elif file_type == 'text':
                            print(wav_label, trans)
if __name__ == '__main__':
    corpus_path = sys.argv[1]
    file_type = sys.argv[2]
    main(corpus_path,file_type)
