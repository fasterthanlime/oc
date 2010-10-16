
import structs/ArrayList

import Expression, Statement, Scope, Var, Type
import middle/Resolver

FuncDecl: class extends Expression {

    resolved := false
    body := Scope new()
    args := ArrayList<Var> new()
    retType := BaseType new("void")

    init: func ~fDecl {}

    resolve: func (task: Task) {
        task queueList(args)
        task queue(retType)
        resolved = true // artificial testing
        
        task queue(body)
        task done()
    }

    toString: func -> String {
        "func"
    }

    getType: func -> Type {
        BaseType new("Func")
    }

}
