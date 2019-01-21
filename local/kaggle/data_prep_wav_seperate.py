import sys,os
from shutil import copyfile

if __name__ == '__main__':
    wav_dir = sys.argv[1]
    data_dir = sys.argv[2]
    for dirPath, dirNames, fileNames in os.walk(sys.argv[1]):
        for fname in fileNames:
            if fname.endswith('.wav'):
                file_path = os.path.join(dirPath, fname)
                file_path = os.path.abspath(file_path)
                name = fname.replace('.wav','')
                decode_dir = os.path.join(data_dir,name,'data')
                if not os.path.isdir(decode_dir):
                    os.makedirs(decode_dir)
                #os.symlink(file_path, os.path.join(decode_dir,fname))
                utt2spk_path = os.path.join(decode_dir,'utt2spk')
                wavscp_path = os.path.join(decode_dir,'wav.scp')
                spk2utt_path = os.path.join(decode_dir,'spk2utt')
                with open(utt2spk_path,'w') as f:
                    f.write(fname + ' ' + fname)
                with open(wavscp_path,'w') as f:
                    f.write(fname + ' ' + file_path)
                with open(spk2utt_path,'w') as f:
                    f.write(fname + ' ' + fname)
                
