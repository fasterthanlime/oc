
printf: extern func

gen: func -> Func -> int {
  return func -> int { return 42 }
}

f1 := gen()
printf("%d\n", f1())
