
use libovum
import ovum/Ast

main: func {

    s := CSource new("hiworld")

    s includes add("<stdio.h>")
    s includes add("<stdlib.h>")
    
    mainFunc := CFunction new(type("int"), "main")
    mainFunc args add(var(type("int"), "argc")).
                  add(var(type("char**"), "argv"))
                 
    mainFunc body add(call("printf", str("Hi, world!\n")))

    stru := CStructDecl new("hello_data")
    stru elements add(var(type("char*"), "name")).
		  add(var(type("int"), "age"))
    s types add(stru)

    mainFunc body add(assign(var(stru type pointer(), "john_doe"), call("malloc", call("sizeof", stru type)))).
		  add(assign(accArrow(acc("john_doe"), "name"), str("John Doe"))).
		  add(assign(accArrow(acc("john_doe"), "age"), int(42))).
		  add(call("printf", str("His name is %s and his age is %d!\n"), accArrow(acc("john_doe"), "name"), accArrow(acc("john_doe"), "age")))
                 
    s functions add(mainFunc)
    
    s write("ovum_tmp/")

}
