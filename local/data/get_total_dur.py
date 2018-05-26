import sys,os
datadir = sys.argv[1]

total = 0.0
with open(os.path.join(datadir,'utt2dur'),'r') as f:
    for line in f:
        tokens = line.rstrip().split()
        dur = float(tokens[1])
        total += dur
print('Total : {:f} minutes.'.format(total/60))
