
import structs/HashMap

import Expression, Statement, Scope, Var, Type, Access
import middle/Resolver

FuncDecl: class extends Expression {

    resolved := false
    body := Scope new()
    args := HashMap<String, Var> new()
    
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
    
    resolveAccess: func (acc: Access, task: Task, suggest: Func (Var)) {
        v := args get(acc name)
        if(v) suggest(v)
    }

    toString: func -> String {
        b := Buffer new()
        b append("func (")
        first := true
        for(arg in args) {
            if(first) first = false
            else      b append(", ")
            b append(arg toString())
        }
        b append(") -> ")
        b append(retType toString())
        b toString()
    }

    getType: func -> Type {
        _type
    }

}
