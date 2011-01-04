
import structs/[ArrayList, HashMap]

import Expression, Statement, Scope, Var, Type, Access, Return, Call
import middle/Resolver

FuncDecl: class extends Expression {

    global := false

    resolved := false
    body := Scope new()
    args := HashMap<String, Var> new()
    
    retType := VoidType new()
    _type: FuncType
    
    externName: String { get set }
    name: String { get set }
    
    // for closures
    accesses: ArrayList<Access>

    init: func ~fDecl {
        name = ""
        externName = null
        _type = FuncType new(this)
    }
    
    anon?: func -> Bool {
        name empty?()
    }
    
    markAccess: func (acc: Access) {
        if(!accesses) {
            accesses = ArrayList<Access> new()
        } else {
            for(acc2 in accesses) {
                if(acc name == acc2 name) return
            }
        }
        "%s is accessing %s" printfln(toString(), acc toString())
        accesses add(acc)
    }

    resolve: func (task: Task) {
        task queueList(args)
        task queue(retType)
        resolved = true // artificial testing
        
        task queue(body)
        inferType(task)
        autoReturn(task)
    }
    
    inferType: func (task: Task) {
        match (task parent node) {
            case c: Call =>
                "Parent of %s is call %s" printfln(toString(), c toString())
                idx := c args indexOf(this)
                "idx = %d, ref = %s" printfln(idx, c ref ? c ref toString() : "(nil)")
        }
    }
    
    autoReturn: func (task: Task) {
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
