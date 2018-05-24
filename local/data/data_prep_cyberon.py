import sys,os

#coding=utf-8
##Usage python data_prep.py <corpus_path> <cyberon_train/cyberon_test> <type : text/wav.scp/utt2spk>
#cps1_test_spk = ['F0095','F0096','F0097','M0094','M0095','M0096']
#cps3_test_spk = ['F0100','F0096','F0097','M0094','M0095','M0096']
cps1_test_spk = ['F0096','F0097','M0095','M0096']
cps3_test_spk = ['F0100','F0097','M0095','M0096']

def check_wav(wav):
    spk = wav.split('\\')[1]
    if len(spk) != 5 or spk[1] != '0':
        return False
    return True
def check_train_set(wav,file_name):
    spk = wav.split('\\')[1]
    if file_name == 'CPS1.txt':
        if spk in cps1_test_spk:
            return False
        else:
            return True
    else:
        if spk in cps3_test_spk:
            return False
        else:
            return True

def main(cyberon_path, is_train, file_type):
    for file_name in ['CPS1.txt','CPS3-1.txt','CPS3-2.txt']:
        with open(os.path.join(cyberon_path,file_name),'r') as f:
            for line in f:
                tokens = line.rstrip().split()
                trans,wav = tokens[1],tokens[0]
                if not check_wav(wav):
                    continue
                # training set
                if is_train and not check_train_set(wav,file_name):
                    continue
                #testing set
                if not is_train and check_train_set(wav,file_name):
                    continue
                #wav_label
                wav_label = wav.replace('\\','-').replace('_','').replace('CPS1','CPS1-1').replace('Sen0','SenISO0')
                #print(wav,wav_label)
                #wav_abs_path
                wav_path = wav.replace('\\','/')
                wav_path = os.path.join(cyberon_path,wav_path)
                wav_path = os.path.abspath(wav_path)
                #transcription
                trans = ' '.join(list(trans))
                #spk
                spk = wav.split('\\')[0] + '-' +  wav.split('\\')[1]
                spk = spk.replace('_','-')
                if file_type == 'text':
                    print(wav_label,trans)
                elif file_type == 'wav.scp':
                    print(wav_label,wav_path)
                elif file_type == 'utt2spk':
                    print(wav_label, spk)
                
if __name__ == '__main__':
    cyberon_path = sys.argv[1]
    is_train = sys.argv[2]
    file_type = sys.argv[3]
    if is_train == 'cyberon_train':
        is_train = True
    else:
        is_train = False
    main(cyberon_path,is_train,file_type)

