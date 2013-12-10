
printf: extern func

gen: func -> Func -> int {
  func -> int { 42 }
}

f1 := gen(42)
printf("%d\n", f1())
