import sys,re
if __name__ == '__main__':
    texts_path = sys.argv[1]
    words_path = sys.argv[2]
    words = []
    with open(words_path,'r') as f:
        for line in f:
            line = line.rstrip()
            words.append(line)
    words = set(words)
    with open(texts_path,'r') as f:
        for line in f:
            line = line.rstrip()
            new_line = ''
            for token in line.split():
                if token not in words:
                    if len(re.findall(u'[\u4e00-\u9fff]+', token)) != 0:
                        if len(token) == 1:
                            print(token)
                        token = ' '.join(token)
                new_line = new_line + ' ' + token
            print(new_line)

            

