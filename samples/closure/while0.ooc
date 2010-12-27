
printf: extern func

while0: func (cond: Func -> Bool, block: Func) {
    cond() ifTrue(||
        block()
        while0(cond, block)
    )
}

while0(func -> int { 1 }, ||
    printf("%s\n", "Hi there!")
)
