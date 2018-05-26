import os,sys

def main(tocfl_path,file_type):
    wavdir_path = os.path.join(tocfl_path,'wav')
    wavdir_path = os.path.abspath(wavdir_path)
    txt_path = os.path.join(tocfl_path,'txt')
    for filename in os.listdir(wavdir_path):
        wav_label = filename.split('.')[0]
        wav_path = os.path.join(wavdir_path,filename)
        txt_file = os.path.join(txt_path,wav_label+'.txt')
        txt = open(txt_file,'r',encoding='UTF-8').read()
        trans = txt.rstrip()
        #trans = ' '.join(list(trans))
        if file_type == 'text':
            sys.path.append('local/data/tool/jieba-zh_TW')
            import jieba
            trans = ' '.join(jieba.cut(trans))
            print(wav_label,trans)
        elif file_type == 'wav.scp':
            print(wav_label,wav_path)
        elif file_type == 'utt2spk':
            print(wav_label, wav_label)
if __name__ == '__main__':
    tocfl_path = sys.argv[1]
    file_type = sys.argv[2]
    main(tocfl_path,file_type)

