#type RangedArray[N: range[3..high(int)]] = array[N, int]
#let g = RangedArray([1, 1, 1])
#echo g

#type HilariousArray[N] = array[N, int]
#var f: HilariousArray[0.5]
#echo f
#static: echo "uh oh"
#static: echo "phew"
import math

type HilariousArray[N: static[uint]] = array[N, int]
var f: array[2^31, byte]#HilariousArray[uint(2 ^ 36)]
echo f