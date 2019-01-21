import os,sys
from shutil import copyfile
error_list = sys.argv[1]
src_dir = sys.argv[2]
target_dir = sys.argv[3]


if not os.path.isdir(target_dir):
    os.makedirs(target_dir)

with open(error_list,'r') as f:
    for line in f:
        name = line.rstrip()
        src = os.path.join(src_dir,name)
        target = os.path.join(target_dir,name)
        print("Copy {} to {} ".format(src,target))
        copyfile(src,target)
