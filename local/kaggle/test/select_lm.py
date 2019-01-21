import sys,os

def process_C2(src_dir,dirname,C_lang_dir,lang):
    idx = int(dirname[1:])
    lm = os.path.join(C_lang_dir,lang,'rescore')
    if lm is not None:
        rescore_lang = os.path.join(src_dir,dirname,'rescore_lang')
        with open(rescore_lang,'w') as f:
            f.write(lm)

if __name__ == '__main__':
    src_dir = sys.argv[1]
    C_lang_dir = sys.argv[2]
    d_list1 = []
    C_langs = os.listdir(C_lang_dir)
    lang_id = 0
    for dirname in os.listdir(src_dir):
        if not os.path.isdir(os.path.join(src_dir,dirname)):
            continue
        idx = int(dirname[1:])
        typ = dirname[0]
        if idx % 3 == 0 and idx <= 1500:
            use_gpu = os.path.join(src_dir,dirname,'use_gpu')
            with open(use_gpu,'w') as f:
                f.write('yes')
        if typ == 'C':
            process_C2(src_dir,dirname,C_lang_dir,C_langs[lang_id])
            lang_id += 1
            
