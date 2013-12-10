
printf: extern func

gen: func (i: int) -> Func -> int {
  func -> int { i }
}

f1 := gen(42)
printf("%d\n", f1())
