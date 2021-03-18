import strutils

type BigInt = seq[int64]

proc `and`(a1, a2: BigInt): BigInt =
    for i in countup(0, a1.len-1):
        echo i
        result.add a1[i] and a2[i]

proc `$`(a: BigInt): string =
    for i in a:
        result &= i.toBin(64)

proc fromString(s: string): BigInt =
    #echo len(s) div 8
    #echo len s
    for i in countup(0, len(s) div 8 - 1):
        result.add cast[int64]((cast[ptr cstringArray](cstring s[i * 8 .. i * 8 + 7]))[])

let
    a = fromString "hbcdefghe"
    b = fromString "hjklmnohv"
    c = a and b

echo a
echo b

echo cast[array[9, char]](c)