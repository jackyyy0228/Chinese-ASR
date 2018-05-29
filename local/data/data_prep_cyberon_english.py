import sys,os

#coding=utf-8
##Usage python data_prep.py <corpus_path> <cyberon_train/cyberon_test> <type : text/wav.scp/utt2spk>
#cps1_test_spk = ['F0095','F0096','F0097','M0094','M0095','M0096']
#cps3_test_spk = ['F0100','F0096','F0097','M0094','M0095','M0096']
cps3_1_test_spk = ['F0095','F0094','M0093','M0094']
cps3_2_test_spk = ['F0093','F0094','M0093','M0094']

def check_train_set(wav,file_name):
    spk = wav.split('\\')[1]
    if file_name == 'Tweng_Cps3-1/TWENG_CPS3-1.spt':
        if spk in cps3_1_test_spk:
            return False
        else:
            return True
    else:
        if spk in cps3_2_test_spk:
            return False
        else:
            return True
def modify_spk(wav):
    spk = wav.split('\\')[1]
    if len(spk) > 7:
        modify_spk = spk[:7]
    else:
        modify_spk = spk
        for _ in range(7-len(spk)):
            modify_spk = modify_spk + '0'
    modify_spk = modify_spk.replace('_','A')
    wav = wav.replace(spk,modify_spk)
    return wav
def main(cyberon_path, is_train, file_type):
    for file_name in ['Tweng_Cps3-1/TWENG_CPS3-1.spt','Tweng_Cps3-2/TWENG_CPS3-2.spt']:
        with open(os.path.join(cyberon_path,file_name),'r') as f:
            for line in f:
                tokens = line.rstrip().split()
                trans,wav = tokens[1],tokens[0]
                wav = wav.replace('TWENG_CPS3','Tweng_Cps3') ##fix path
                # training set
                modify_wav = modify_spk(wav)
                if is_train and not check_train_set(wav,file_name):
                    continue
                #testing set
                if not is_train and check_train_set(wav,file_name):
                    continue
                #wav_label
                wav_label = modify_wav.replace('\\','-').replace('_','').replace('Sen0','Senppc0')
                #print(wav,wav_label)
                #wav_abs_path
                wav_path = wav.replace('\\','/')
                wav_path = os.path.join(cyberon_path,wav_path)
                wav_path = os.path.abspath(wav_path)
                #transcription
                #trans = ' '.join(list(trans))
                #spk
                spk = modify_wav.split('\\')[0] + '-' +  modify_wav.split('\\')[1]
                spk = spk.replace('_','-')
                if file_type == 'text':
                    trans = trans.replace('-',' ').upper()
                    print(wav_label,trans)
                elif file_type == 'wav.scp':
                    print(wav_label,wav_path)
                elif file_type == 'utt2spk':
                    print(wav_label, spk)
                
if __name__ == '__main__':
    cyberon_path = sys.argv[1]
    is_train = sys.argv[2]
    file_type = sys.argv[3]
    if is_train == 'cyberon_english_train':
        is_train = True
    else:
        is_train = False
    main(cyberon_path,is_train,file_type)

