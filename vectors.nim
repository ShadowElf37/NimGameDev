import math
import random
import sets

randomize()

type
    Vector[N: static int] = array[N, float64]
    Polygon[X: static int, N: static int] = array[X, Vector[N]]


proc edges*[X: static int, N: static int](shape: Polygon[X, N]): array[X, array[2, Vector[N]]] =
    for i, point in shape.pairs():
        if i == shape.len-1:
            result[i] = [point, shape[0]]
            return result
        result[i] = [point, shape[i+1]]
proc edge_vectors*[X: static int, N: static int](shape: Polygon[X, N]): array[X, Vector[N]] =
    let e = shape.edges
    for i, edge in e.pairs():
        result[i] = edge[1] - edge[0]

proc offset*[X: static int, N: static int](shape: Polygon[X, N], offset_vector: Vector[2]): Polygon[X, N] =
    for i, point in shape.pairs():
        result[i] = point + offset_vector


proc newVector*[N: static[int]](elements: varargs[float64, float64]): Vector[N] =
    when N < 1:
        raise newException(ValueError, "Vector dimension must be 1 or greater")

    for i, elem in elements.pairs():
        result[i] = elem

proc randVector*[N: static[int]](max_float=1.0): Vector[N] =
    when N < 1:
        raise newException(ValueError, "Vector dimension must be 1 or greater")

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

proc x*(v: Vector): float64 = v[0]
proc y*(v: Vector): float64 = v[1]
proc z*(v: Vector): float64 = v[2]
proc w*(v: Vector): float64 = v[3]

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
proc map*[N: static[int]](f: proc (i: float64): float64, v: Vector[N]): Vector[N] =
    for i in countup(0, N-1):
        result[i] = f(v[i])

proc all*[N: static[int], T](v: array[N, T]|Vector[N], cmp: (proc(i: T): bool)=(proc(i:T): bool=bool(i))): bool =
    for i in v:
        if not cmp(i):
            return false
    return true
proc all_positive*[N: static[int], T](v: array[N, T]|Vector[N]): bool =
    v.all(proc(i:int):bool=i>0)
proc all_positive_or_zero*[N: static[int], T](v: array[N, T]|Vector[N]): bool =
    v.all(proc(i:int):bool=i>=0)

proc zero*[N: static[int], T](v: Vector[N]): bool =
    v.all(proc(i:int):bool=i==0)

template testAll*[N: static[int]](v: Vector[N], condition: untyped) =
    ## USE `e` AS GENERIC ELEMENT
    (proc (): bool =
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
proc proj_coeff*[N: static[int]](v: Vector[N], onto_v: Vector[N]): float =
    ((v * onto_v) / (onto_v * onto_v))
proc proj_sign*[N: static[int]](v: Vector[N], onto_v: Vector[N]): int =
    return sgn(v * onto_v)
proc proj*[N: static[int]](v: Vector[N], onto_v: Vector[N]): Vector[N] =
    proj_coeff(v, onto_v) * onto_v

proc decompose2D_coeffs*(v, basis1, basis2: Vector[2]): array[2, float] =
    let
        b1b2 = basis1 * basis2
        b1b1 = basis1 * basis1
        b2b2 = basis2 * basis2
        vb1 = v * basis1
        vb2 = v * basis2
        det = b1b1 * b2b2 - b1b2 ^ 2

    return [
        (vb1 * b2b2 - vb2 * b1b2) / det,
        (vb2 * b1b1 - vb1 * b1b2) / det
    ]
proc decompose2D_signs*(v, basis1, basis2: Vector[2]): array[2, int] =
    let
        b1b2 = basis1 * basis2
        b1b1 = basis1 * basis1
        b2b2 = basis2 * basis2
        vb1 = v * basis1
        vb2 = v * basis2
        det = b1b1 * b2b2 - b1b2 ^ 2

    return [
        sgn (vb1 * b2b2 - vb2 * b1b2) / det,
        sgn (vb2 * b1b1 - vb1 * b1b2) / det
    ]

proc randomOrth*[N: static[int]](v: Vector[N]): Vector[N] =
    # returns a random vector orthogonal to v
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

proc scalarDenominator*[N: static[int]](v1, v2: Vector[N]): float =
    var temp = newVector[N]()
    for i in countup(0, temp.len-1):
        temp[i] = v1[i] / v2[i]

    when N == 1:
        return temp[0]
    else:
        for elem in temp[1..<temp.len]:
            if abs(temp[0] - elem) > 0.00001:
                return 0
        return temp[0]

proc withinVectors2D*(v, b1, b2: Vector[2]): bool =
    if scalarDenominator(b1, b2) != 0:
        let
            mv = @v
            mb1 = b1 * v
            mb2 = b2 * v
        return min(mb1, mb2) < mv and mv < max(mb1, mb2)
    return decompose2D_signs(v, b1, b2).all_positive

let test = decompose2D_signs(v2(5, -3), v2(1, 0), v2(1, 1))

echo test

echo withinVectors2D(v2(1, 1), v2(1, 0), v2(0, 1))
echo withinVectors2D(v2(2, 1), v2(1, 0), v2(0, 1))
echo withinVectors2D(v2(1, -1), v2(1, 0), v2(0, 1))


let shape1 = Polygon [
    v2(1, 1),
    v2(1, -1),
    v2(-1, -1),
    v2(-1, 1)
]

let shape2 = Polygon [
    v2(2, 2),
    v2(2, 0),
    v2(0.9, 0),
    v2(0.9, 2)
]

echo edges(shape1)
echo edge_vectors(shape1)

var
    perp, axis, dist, temp: Vector[2]
    shape1outer, shape2outer: array[2, Vector[2]]
    shapemaxmin_set: array[4, bool]

for edge in shape1.edge_vectors:
    axis = randomOrth(edge)
    for point in shape1:
        if not shapemaxmin_set[0]:
            shape1max = point
            shapemaxmin_set[0] = true
        if not shapemaxmin_set[1]:
            shape1min = point
            shapemaxmin_set[1] = true

    dist = (center(shape1) - center(shape2)).proj(axis)

    for point in shape1:
        temp = point.proj(axis)

