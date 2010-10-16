
fib := n -> {
  fibIter := (a, b, i) -> match {
    i > 0 => fibIter(b, a + b, i - 1)
    _     => a + b
  }
  fibIter(1, 1, n - 1)
}

range(0, 20) each(x ->
  print(fib(x))
)
