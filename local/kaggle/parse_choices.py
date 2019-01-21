# -*- coding: utf-8 -*-

import sys,os,re
def check_regular(text):
    if re.match('^<one>.*<two>.*<three>.*<four>',text):
        for x in ['<one>','<two>','<three>','<four>']:
            if text.count(x) != 1:
                return False
        return True
    else:
        return False

def parse(text):
    if check_regular(text):
        s1 = text.find("<two>")
        s2 = text.find("<three>")
        s3 = text.find("<four>")
        texts = [text[5:s1],text[s1+5:s2],text[s2+7:s3],text[s3+6:]]
        for i in range(len(texts)):
            if texts[i].startswith(' '):
                texts[i] == texts[i][1:]
        return texts
    text =text.replace('<one>','一').replace('<two>','二').replace('<three>','三').replace('<four>','四')
    ones = ['一，','1，','一','1','依','遺','伊']
    others = [['二','爾','俄','愕','而','耳','阿','惡','遏','厄','額','鄂','餓','顎','蛾','兒','鱷','俄','扼','餓','的','和','。2','，2','2'],['，三','。三','三','撒','杉','參','山','僧','生','聲','身','商','霜','散','，3','。3','3'],['，四','。四','四', '似', '是','飾','伺','寺','市','式','士','世','室','視','試','勢','氏','釋','柿','事','示','食','適','持','逝','失','賜','思','死','侍','師','飼','誓','自','時','司','子','絲','獅','使','刺','次','字','十','嗣','私','祀','斯','汜','，4','。4','4']]
    for one in ones:
        if text.startswith(one):
            leng=len(one)
            text = text[leng:]
            break
    texts = ['空字號' for _ in range(4)]
    prev = 0
    for idx,other in enumerate(others):
        for token in other:
            start = text.find(token)
            if start != -1:
                texts[prev] = text[:start]
                text = text[start+len(token):]
                text = text.lstrip('，')
                prev = idx + 1 
                break
    texts[prev] = text
    return texts
if __name__ == '__main__':
    choices_file =  sys.argv[1]
    with open(choices_file,'r') as f:
        for line in f:
            tokens = line.rstrip().split()
            text = ''.join(tokens[1:])
            name = tokens[0]
            No = int(name[1:])
            parse(text)
            #print(text,parse(text))
