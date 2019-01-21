import sys,os
sys.path.append('local/data/')
from normalize_utils import *
def check_new_delete_word(text_path):
    new_text = ''
    with open(text_path,'r',encoding='utf-8') as f:
        for line in f:
            new_text += line
    S1 = check_not_chinese(new_text)
    S2 = set(delete_symbols)
    for x in list(S1-S2):
        print(x)
    exit()


if __name__ == '__main__':
    text_path = sys.argv[1]
    output_path = sys.argv[2]
    new_text = ''
    #check_new_delete_word(text_path)
    word_list = get_word_list('data/lang/words.txt')
    with open(text_path,'r',encoding='utf-8') as f:
        for line in f:
            if 'ETtoday' in line:
                continue
            line = line.rstrip()
            new_text += normalize(line,word_list) + '\n'
    with open(output_path,'w',encoding='utf-8') as f:
        f.write(new_text)



