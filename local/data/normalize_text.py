import sys,re
from number2chinese import *

not_in_word=[ '`', '÷', '×', '≠', '<', '>', '|', '°', '┬', '┐', '├', '┼', '┤', '└', '┴', '│', '¯', '-', ';', '!', '¿', '·', '‘', '’', '"', '(', ')', '[', ']', '{', '}', '§', '®', '™', '@', '$', '€', '*', '&', '&&', '&&&', '±', '━', '←', '→', '↑', '↓', '♪', '╱', '╲', '◢', '◣', 'ˋ', '▁', '\x1b', '\x7f', '\x80', '¼', '½', '-', 'Á', 'À', 'Â', 'Å', 'Ä', 'Ā','（ ','˙','!', '(', ')', '-', '.', ':', '<', '>', '·', 'β', '—', '•', '℃', '。', '《', '》', 'ㄅ', 'ㄆ', 'ㄇ', 'ㄈ', 'ㄔ', 'ㄙ', 'ㄞ', 'ㄟ', '一', '\ue015', '\ue028', '\ufeff', '．', '：', 'Ｃ', 'Ｄ', 'Ｅ', 'Ｉ', 'Ｋ', 'Ｔ']

if __name__ == '__main__':
    texts_path = sys.argv[1]
    words_path = sys.argv[2]
    
    words = []
    with open(words_path,'r',encoding='utf-8') as f:
        for line in f:
            line = line.rstrip()
            words.append(line)
    words = set(words)

    with open(texts_path,'r',encoding='utf-8') as f:
        for line in f:
            line = line.rstrip()
            tokens = line.split()
            new_line = ''
            for token in tokens:
                if re.match('^[0-9]+$',token):
                    if len(token) > 15:
                        continue
                    token = to_chinese(int(token))
                if token in not_in_word :
                    continue
                if token not in words:
                    if len(re.findall(u'[\u4e00-\u9fff]+', token)) != 0:
                        if len(token) > 1:
                            token = ' '.join(token)
                new_line = new_line + token + ' '
            print(new_line)


            

