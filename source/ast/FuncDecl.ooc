
import structs/HashMap

import Expression, Statement, Scope, Var, Type, Access, Return
import middle/Resolver

FuncDecl: class extends Expression {

    resolved := false
    body := Scope new()
    args := HashMap<String, Var> new()
    
    retType := VoidType new()
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
        if(!retType void?()) {
            list := body body
            if(list empty?()) {
                "Expected return expression in non-void function %s" printfln(name)
                exit(1)
            } else {
                last := list last()
                if(last class == Return) {
                    // all good
                } else if(last instanceOf?(Expression)) {
                    list set(list size - 1, Return new(last as Expression))
                } else {
                    "Expected return expression in non-void function %s" printfln(name)
                    exit(1)
                }
            }
        }
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
