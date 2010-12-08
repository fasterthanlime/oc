
printf: extern func

while: func (cond: Func -> Bool, block: Func) {
    if(cond(), ||
        block()
        while0(cond, block)
    )
}

while(|| true, ||
    printf("%s\n", Hi there!)
)
