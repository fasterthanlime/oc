
reduce := x, op -> match x {
    [y, z] => op(y, z)
    [y, _] => op(y, reduce(_, op))
}
reduce(args, (a, b) -> a + ", " + b) println()
