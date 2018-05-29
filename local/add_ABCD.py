import sys
if __name__ == '__main__':
    arpa = sys.argv[1]
    output = sys.argv[2]
    all_lines = []
    with open(arpa,'r',encoding='utf-8') as f:
        for line in f:
            line = line.rstrip()
            sig = True
            for x in ['A','B','C','D']:
                if ' <s> {} -'.format(x) in line:
                    sig = False
                    all_lines.append('-2.00000 <s> {} -0.10000'.format(x))
                    break
            if sig:
                all_lines.append(line)
    with open(output,'w',encoding='utf-8') as f:
        for line in all_lines:
            f.write(line + '\n')

