import subprocess
import parse_choices as pc

def asr(A_path, B_path, C_path):
    # Inputs :
    # A_path : path of context wav
    # B_path : path of question wav
    # C_path : path of option wav
    # Outputs : 
    # {"context":"","question":"","options":["","","",""], "answer":-1}
    
    outputs = subprocess.check_output(['bash' ,'/data/local/kgb/Chinese-ASR/local/kaggle/decode_demo.sh', A_path, B_path, C_path ])
    d = {"context":"","question":"","options":["","","",""], "answer":-1}
    for line in outputs.decode('utf-8').split('\n'):
        if len(line) == 0 :
            continue
        line = line.replace('<UNK>','')
        tokens = line.split()
        typ = tokens[0]
        trans = ' '.join(tokens[1:])
        if typ == 'A':
            d['context'] = trans
        elif typ == 'B':
            d['question'] = trans
        elif typ == 'C':
            d['options'] = pc.parse(trans.replace(' ',''))
    return d

if __name__ == '__main__':
    A_path = '/data/local/kgb/Chinese-ASR/one_qa/A0001500.wav'
    B_path = '/data/local/kgb/Chinese-ASR/one_qa/B0001500.wav'
    C_path = '/data/local/kgb/Chinese-ASR/one_qa/C0001500.wav'
    d = asr(A_path,B_path,C_path)
    print(d)
