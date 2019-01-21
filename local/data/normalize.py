import string,sys
import re
from number2chinese import * 

fin = sys.argv[1]
fout = sys.argv[2]

l = []
with open(fin,'r') as f:
    for line in f:
        for cha in [' ','、','「','」','”','“','…','）','）','：']:
            line = line.replace(cha,'')
        for cha in string.punctuation:
            line = line.replace(cha,'')
        for cha in ['，',':','?','、','。','；','！']:
            line = line.replace(cha,'\n')
        line = line.replace('\n\n','\n')
        if len(line) >= 1:
            ## 我是john先生 -> 我 是 john 先 生
            newline = ''
            flag = True
            for char in line:
                if re.match('^[a-zA-Z0-9]+$',char):
                    flag = False
                    newline += char
                else:
                    if not flag:
                        newline += ' '
                    flag = True
                    newline += char + ' '
            if flag:
                newline = newline[:-1]
            #covert number to chinese
            line = ''
            for token in newline.split(' '):
                if re.match('^[0-9]+$',token):
                    if len(token) > 15:
                        break
                    token = to_chinese(int(token))
                    token = ' '.join(list(token))
                line += token + ' '
            l.append(line[:-1])
with open(fout,'w') as f:
    for line in l:
        f.write(line)
