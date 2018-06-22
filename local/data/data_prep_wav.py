import sys,os


if __name__ == '__main__':
    wav_dir = sys.argv[1]
    data_dir = sys.argv[2]
    utt2spk_path = os.path.join(data_dir,'utt2spk')
    wavscp_path = os.path.join(data_dir,'wav.scp')
    with open(utt2spk_path,'w') as f1, open(wavscp_path,'w') as f2:
        for dirPath, dirNames, fileNames in os.walk(sys.argv[1]):
            for name in fileNames:
                file_name = os.path.join(dirPath, name)
                f1.write(name + ' ' + name + '\n')
                f2.write(name + ' ' + file_name + '\n')
    
