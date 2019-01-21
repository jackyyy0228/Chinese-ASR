import os,sys,json
wav_dir = sys.argv[1]
output_json = sys.argv[2]
L = []
for wav in os.listdir(wav_dir):
    if wav.endswith('.wav'):
        name = wav[1:].replace('.wav','')
        idx = int(name)
        L.append(idx)
json.dump(L,open(output_json,'w'))
    

