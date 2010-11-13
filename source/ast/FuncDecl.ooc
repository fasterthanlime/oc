
import structs/ArrayList

import Expression, Statement, Scope, Var, Type
import middle/Resolver

FuncDecl: class extends Expression {

    resolved := false
    body := Scope new()
    args := ArrayList<Var> new()
    retType := BaseType new("void")
    
    externName: String { get set }
    name: String { get set }

    init: func ~fDecl {
        name = ""
        externName = null
    }

    resolve: func (task: Task) {
        task queueList(args)
        task queue(retType)
        resolved = true // artificial testing
        
        task queue(body)
    }

    toString: func -> String {
        "func"
    }

    getType: func -> Type {
        BaseType new("Func")
    }

}
