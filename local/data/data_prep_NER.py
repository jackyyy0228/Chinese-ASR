import os,sys

def main(corpus_path,file_type):
    for root, dirs, files in os.walk(corpus_path, topdown=False):
        for name in files:
            if name.endswith('.wav'):
                wav_label = name.split('.')[0]
                wav_path = os.path.join(root,name)
                wav_path = os.path.abspath(wav_path)
                
                txt_path = wav_path.replace('Wav','Text').replace('.wav','.txt')
                if not os.path.isfile(txt_path):
                    continue
                trans = open(txt_path,'r', encoding='utf-8').read()
                trans = trans.rstrip()

                if file_type == 'wav.scp':
                    print(wav_label, wav_path)
                elif file_type == 'utt2spk':
                    print(wav_label, wav_label)
                elif file_type == 'text':
                    print(wav_label, trans)
if __name__ == '__main__':
    corpus_path = sys.argv[1]
    file_type = sys.argv[2]
    main(corpus_path,file_type)
