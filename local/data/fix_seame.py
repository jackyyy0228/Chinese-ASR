import sys,os

def get_labels(file_path):
    s = set()
    with open(file_path,'r') as f:
        for line in f:
            token  = line.split()[0]
            s.add(token)
    return s
    
if __name__ == '__main__':
    data_path = sys.argv[1]
    s1 = get_labels(os.path.join(data_path,'segments'))  
    s2 = get_labels(os.path.join(data_path,'feats.scp'))
    s3 = s1 - s2
    for scp in ['text','utt2spk','spk2utt','segments']:
        all_lines = []
        with open(os.path.join(data_path,scp),'r') as f:
            for line in f:
                token = line.split()[0]
                if token in s3:
                    continue
                else:
                    all_lines.append(line)
        with open(os.path.join(data_path,scp),'w') as f:
            for line in all_lines:
                f.write(line)


