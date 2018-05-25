import os,sys
def main(pts_path,file_type):
    for root, dirs, files in os.walk(pts_path, topdown=False):
        for name in files:
            if name.endswith('.wav'):
                wav_label = name.split('.')[0]
                wav_path = os.path.join(root,name)
                wav_path = os.path.abspath(wav_path)
                if file_type == 'wav.scp':
                    print(wav_label,wav_path)
if __name__ == '__main__':
    pts_path = sys.argv[1]
    file_type = sys.argv[2]
    main(pts_path,file_type)

