
printf: extern func

exec: func (f: Func) {
    f()
}

exec(func {
  printf("Exec works :)\n")
})
