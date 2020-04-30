import json
import codecs,sys
import sys

if len(sys.argv)<3:
    print("Usage " + sys.argv[0] + " <input file>  <element> <optional subelement>")
    sys.exit(1)


filename=sys.argv[1]
element1=sys.argv[2]
element2=None
if (len(sys.argv)>3):
    element2=sys.argv[3]


json_struct=json.load(codecs.open(filename, 'r', 'utf-8-sig'))

if (element2==None):
    print(json_struct[element1])
else:
    print(json_struct[element1][element2])


