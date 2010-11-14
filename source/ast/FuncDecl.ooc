
import structs/ArrayList

import Expression, Statement, Scope, Var, Type
import middle/Resolver

FuncDecl: class extends Expression {

    resolved := false
    body := Scope new()
    args := ArrayList<Var> new()
    retType := BaseType new("void")
    _type: FuncType
    
    externName: String { get set }
    name: String { get set }

    init: func ~fDecl {
        name = ""
        externName = null
        _type = FuncType new(this)
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
        _type
    }

}
