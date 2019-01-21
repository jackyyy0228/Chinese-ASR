import sys,os
from shutil import copyfile

def read_choose_lm(choose_lm):
    d = {}
    with open(choose_lm,'r') as f:
        for line in f:
            tokens = line.rstrip().split()
            idx = int(tokens[0][1:].replace('.wav',''))
            novel = tokens[1]
            ##modify mode
            d[idx] = novel
    return d
def inverse_dict(my_map):
    inv_map = {}
    for k, v in my_map.items():
        inv_map[v] = inv_map.get(v, [])
        inv_map[v].append(k)
    return inv_map
def num_to_7digits(num):
    num = str(num)
    new = num
    for idx in range(7-len(num)):
        new = '0' + new
    return new
if __name__ == '__main__':
    wav_dir = sys.argv[1]
    data_dir = sys.argv[2]
    choose_lm_file = sys.argv[3]
    type_qa = sys.argv[4] # A B C

    d_lm = read_choose_lm(choose_lm_file)
    inv_d_lm = inverse_dict(d_lm)
    def my_key(x):
        if x[0].endswith('_pruned'):
            return len(x[1]) + 1000
        else:
            if x[0] == 'news' or x[0] == 'ori':
                return -len(x[1]) -1000
            else:
                return -len(x[1])
    with open(os.path.join(data_dir,'all_lms'),'w') as f:
        for lm,wav_ids in sorted(inv_d_lm.items(), key=my_key):
            f.write(lm+'\n')
        
    for lm, wav_ids in sorted(inv_d_lm.items(), key=lambda x: len(x[1])):
        decode_dir = os.path.join(data_dir,lm,'data')
        if not os.path.isdir(decode_dir):
            os.makedirs(decode_dir)
        utt2spk_path = os.path.join(decode_dir,'utt2spk')
        wavscp_path = os.path.join(decode_dir,'wav.scp')
        spk2utt_path = os.path.join(decode_dir,'spk2utt')
        rescore_path = os.path.join(data_dir,lm,'rescore_lang')
        mode_path = os.path.join(data_dir,lm,'mode')
        nj_path = os.path.join(data_dir,lm,'nj')
        
        with open(utt2spk_path,'w') as f:
            for wav_id in wav_ids:
                fname = type_qa + num_to_7digits(wav_id)
                f.write(fname + ' ' + fname + '\n')
        with open(wavscp_path,'w') as f:
            for wav_id in wav_ids:
                fname = type_qa + num_to_7digits(wav_id)
                file_path = os.path.join(wav_dir,fname+'.wav')
                f.write(fname + ' ' + file_path + '\n')
        with open(spk2utt_path,'w') as f:
            for wav_id in wav_ids:
                fname = type_qa + num_to_7digits(wav_id)
                f.write(fname + ' ' + fname + '\n')
        with open(rescore_path,'w') as f:
            prune = ''
            lm_ori = lm.replace('_pruned','').replace('_1','').replace('_2','')
            f.write('data/LM/' + lm_ori + '_' + type_qa )
        with open(mode_path,'w') as f:
            if lm.endswith('_pruned'):
                f.write('5')
            else:
                f.write('4')
        with open(nj_path,'w') as f:
            if type_qa == 'C':
                if len(wav_ids) >= 63:
                    nj = 10
                else:
                    nj = len(wav_ids) // 7 + 1
            else:
                if len(wav_ids) > 150:
                    nj = 15
                else:
                    nj = len(wav_ids) // 10 + 1
            f.write(str(nj))
            
