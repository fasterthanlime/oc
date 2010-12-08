
printf: extern func

exec: func (f: Func) {
    f()
}

exec(||
  printf("Exec works :)\n")
)
