import math
import random
import sets

randomize()

type
    Vector[N: static int] = array[N, float64]

proc newVector*[N: static[int]](elements: varargs[float64, float64]): Vector[N] =
    for i, elem in elements.pairs():
        result[i] = elem

proc randVector*[N: static[int]](max_float=1.0): Vector[N] =
    for i in countup(0, N-1):
        result[i] = rand(max_float)

proc v1*(elements: varargs[float64, float64]): Vector[1] =
    newVector[1](elements)
proc v2*(elements: varargs[float64, float64]): Vector[2] =
    newVector[2](elements)
proc v3*(elements: varargs[float64, float64]): Vector[3] =
    newVector[3](elements)
proc v4*(elements: varargs[float64, float64]): Vector[4] =
    newVector[4](elements)

proc x*(v: Vector): float64 =
    v[0]
proc y*(v: Vector): float64 =
    v[1]
proc z*(v: Vector): float64 =
    v[2]
proc w*(v: Vector): float64 =
    v[3]

proc `==`*[N: static[int]](v1: Vector[N], v2: Vector[N]): bool =
    for i in countup(0, N-1):
        if v1[i] != v2[i]:
            return false
    return true

# More reusable
template twoVectorOperator(name, body) =
    proc name*[N: static[int]](v1 {.inject.}: Vector[N], v2 {.inject.}: Vector[N]): Vector[N] =
        body
template oneVectorOperator(name, body) =
    proc name*[N: static[int]](v {.inject.}: Vector[N]): Vector[N] =
        body
template scalarOperator(name, body) =
    proc name*[N: static[int]](v {.inject.}: Vector[N], x {.inject.}: float64): Vector[N] =
        body
    proc name*[N: static[int]](x {.inject.}: float64, v {.inject.}: Vector[N]): Vector[N] =
        body

template vectorIterative(body) {.dirty.} =
    for i in countup(0, N-1):
        result[i] = body

# ADDITION
twoVectorOperator `+`:
    vectorIterative: v1[i] + v2[i]
twoVectorOperator `-`:
    vectorIterative: v1[i] - v2[i]

# SCALAR MULTIPLICATION
scalarOperator `*`:
    vectorIterative: v[i] * x
scalarOperator `/`:
    vectorIterative: v[i] / x

# NEGATIVE
oneVectorOperator `-`:
    vectorIterative: -v[i]

# SOME NICE FUNCTIONS
proc map*[N: static[int], R](f: proc (i: float64): float64, v: Vector[N]): Vector[N] =
    for i in countup(0, N-1):
        result[i] = f(v[i])

template testAllElems*[N: static[int]](v: Vector[N], condition: untyped) =
    ## USE `e` AS GENERIC ELEMENT
    (proc (): int =
        var e: float64
        for i in countup(0, N-1):
            e = v[i]
            if not (condition):
                return false
        return true
        )()

# DOT
proc dot*[N: static[int]](v1: Vector[N], v2: Vector[N]): float64 =
    for i in countup(0, N-1):
        result += v1[i] * v2[i]
proc `*`*[N: static[int]](v1: Vector[N], v2: Vector[N]): float64 = dot(v1, v2)

# MAGNITUDE
proc magnitude*[N: static[int]](v: Vector[N]): float64 =
    sqrt(v * v)
proc `@`*[N: static[int]](v: Vector[N]): float64 = v.magnitude

# NORMALIZED
proc normalize*[N: static[int]](v: Vector[N]): Vector[N] =
    v / v.magnitude
proc `!`*[N: static[int]](v: Vector[N]): Vector[N] = v.normalize

# DISTANCE
proc distance*[N: static[int]](v1: Vector[N], v2: Vector[N]): float64 =
    for i in countup(0, N-1):
        result += pow(v2[i] - v1[i], 2)
    result = sqrt(result)
proc `---`*[N: static[int]](v1: Vector[N], v2: Vector[N]): float64 = distance(v1, v2)

# ETC
proc proj*[N: static[int]](v: Vector[N], onto_v: Vector[N]): Vector[N] =
    ((v * onto_v) / (onto_v * onto_v)) * onto_v

proc randomOrth*[N: static[int]](v: Vector[N]): Vector[N] =
    let r = randVector[N]()
    result = r - proj(r, v)

proc orthogonal*[N: static[int]](v1: Vector[N], v2: Vector[N]): bool =
    v1 * v2 == 0

proc center*[N: static[int]](vectors: varargs[Vector[N]]): Vector[N] =
    for v in vectors:
        result = result + v
    result = result / float64(vectors.len)

proc dim*[N: static[int]](v: Vector[N]): int =
    v.len()


let shape1 = [
    v2(1, 1),
    v2(1, -1),
    v2(-1, -1),
    v2(-1, 1)
]

let shape2 = [
    v2(2, 2),
    v2(2, 0),
    v2(0.9, 0),
    v2(0.9, 2)
]

let axis = randomOrth(shape1[1] - shape1[0])

let offset = (center(shape1) - center(shape2)).proj(axis)

var
    shape1_minmax: array[2, Vector[2]]
    shape2_minmax: array[2, Vector[2]]
    p: Vector[2]

for vertex in shape1:
    p = proj(vertex, axis)
    if p.dot(axis) < shape1_minmax[0].dot(axis):
        shape1_minmax[0] = p + offset
    elif p.dot(axis) > shape1_minmax[1].dot(axis):
        shape1_minmax[1] = p + offset

for vertex in shape2:
    p = proj(vertex, axis)
    if p.dot(axis) < shape2_minmax[0].dot(axis):
        shape2_minmax[0] = p + offset
    elif p.dot(axis) > shape2_minmax[1].dot(axis):
        shape2_minmax[1] = p + offset


var intersect = true
for i in countup(0, shape1[0].dim()-1):
    if shape1_minmax[0][i] > shape2_minmax[1][i] or shape2_minmax[0][i] > shape1_minmax[1][i]:
        echo "not intersecting"
        intersect = false
        break

if intersect: echo "intersecting"


echo shape1_minmax
echo shape2_minmax
#echo vertices[1] - vertices[0]
#echo axis