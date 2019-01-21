import sys,os

def process_A(src_dir,dirname):
    idx = int(dirname[1:])
    if idx <= 800:
        lm = "lm_test/LM/news_A_kaggle12"
    elif 801 <= idx and idx <= 904:
        lm = "lm_test/LM/3kingdom_A_kaggle12"
    elif 1001 <= idx and idx <= 1086:
        lm = "lm_test/LM/journey_west_A_kaggle12"
    elif 1102 <= idx and idx <= 1250:
        lm = "lm_test/LM/red_mansion_A_kaggle12"
    elif 1251 <= idx and idx <= 1500:
        lm = "lm_test/LM/3kingdom_A_kaggle12"
    elif 1501 <= idx and idx <= 1569:
        lm = "lm_test/LM/hunghuang_A_kaggle12"
    elif 1570 <= idx and idx <= 1844:
        lm = "lm_test/LM/journey_west_A_kaggle12"
    else:
        lm = "lm_test/LM/A_kaggle12"
    if lm is not None:
        rescore_lang = os.path.join(src_dir,dirname,'rescore_lang')
        with open(rescore_lang,'w') as f:
            f.write(lm)

def process_B(src_dir,dirname):
    idx = int(dirname[1:])
    if idx <= 800:
        lm = "lm_test/LM/news_B_kaggle12"
    elif 801 <= idx and idx <= 904:
        lm = "lm_test/LM/3kingdom_B_kaggle12"
    elif 1001 <= idx and idx <= 1086:
        lm = "lm_test/LM/journey_west_B_kaggle12"
    elif 1102 <= idx and idx <= 1250:
        lm = "lm_test/LM/red_mansion_B_kaggle12"
    elif 1251 <= idx and idx <= 1500:
        lm = "lm_test/LM/3kingdom_B_kaggle12"
    elif 1501 <= idx and idx <= 1569:
        lm = "lm_test/LM/hunghuang_B_kaggle12"
    elif 1570 <= idx and idx <= 1844:
        lm = "lm_test/LM/journey_west_B_kaggle12"
    else:
        lm = "lm_test/LM/B_kaggle12"
    if lm is not None:
        rescore_lang = os.path.join(src_dir,dirname,'rescore_lang')
        with open(rescore_lang,'w') as f:
            f.write(lm)
def process_C(src_dir,dirname):
    idx = int(dirname[1:])
    if idx <= 800:
        lm = "lm_test/LM/news_C_kaggle12"
    if 801 <= idx and idx <= 904:
        lm = "lm_test/LM/3kingdom_C_kaggle12"
    elif 1001 <= idx and idx <= 1086:
        lm = "lm_test/LM/journey_west_C_kaggle12"
    elif 1102 <= idx and idx <= 1250:
        lm = "lm_test/LM/red_mansion_C_kaggle12"
    elif 1251 <= idx and idx <= 1500:
        lm = "lm_test/LM/3kingdom_C_kaggle12"
    elif 1501 <= idx and idx <= 1569:
        lm = "lm_test/LM/hunghuang_C_kaggle12"
    elif 1570 <= idx and idx <= 1844:
        lm = "lm_test/LM/journey_west_C_kaggle12"
    else:
        lm = "lm_test/LM/C_kaggle12"
    if lm is not None:
        rescore_lang = os.path.join(src_dir,dirname,'rescore_lang')
        with open(rescore_lang,'w') as f:
            f.write(lm)
def process_C2(src_dir,dirname,C_lang_dir):
    idx = int(dirname[1:])
    lm = os.path.join(C_lang_dir,dirname,'rescore')
    if lm is not None:
        rescore_lang = os.path.join(src_dir,dirname,'rescore_lang')
        with open(rescore_lang,'w') as f:
            f.write(lm)
if __name__ == '__main__':
    src_dir = sys.argv[1]
    C_lang_dir = sys.argv[2]
    for dirname in os.listdir(src_dir):
        if not os.path.isdir(os.path.join(src_dir,dirname)):
            continue
        idx = int(dirname[1:])
        typ = dirname[0]
        if idx % 3 == 0 and idx <= 1500:
            use_gpu = os.path.join(src_dir,dirname,'use_gpu')
            with open(use_gpu,'w') as f:
                f.write('yes')
        if typ == 'A':
            process_A(src_dir,dirname)
        elif typ == 'B':
            process_B(src_dir,dirname)
        elif typ == 'C':
            if C_lang_dir == 'X':
                process_C(src_dir,dirname)
            else:
                process_C2(src_dir,dirname,C_lang_dir)
            
