# This script used for text augmentation to train LMs
# Ex : 河道 全長 約 五十三 公里
#   -> A 河道 全長 約 五十三 公里
#   -> B 河道 全長 約 五十三 公里
#   -> C 河道 全長 約 五十三 公里
#   -> D 河道 全長 約 五十三 公里

import sys
if __name__ == '__main__':
    ratio = float(sys.argv[1])
    text_path = sys.argv[2]
    aug_text_path = sys.argv[3]
