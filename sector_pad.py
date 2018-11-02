import os
import sys
from math import floor
f_name = str(sys.argv[1])
if f_name[3:] == 'img':
    b_size = os.path.getsize(f_name)
    correct_size = (int)(floor(b_size/512) + 1)*512
    pad = correct_size - b_size
    with open(f_name, "ab") as myfile:
        for i in range(pad):
            myfile.write("\0")
    print("padded {0} with {1} bytes".format(f_name, pad))
else:
    print("could not pad file -- not valid image")
