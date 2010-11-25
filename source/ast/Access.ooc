

import middle/Resolver
import Expression, Type, Var, Node, Scope, Statement, FuncDecl

Access: class extends Expression {

    name: String { get set }
    expr: Expression { get set }
    
    ref: Var { get set }

    init: func (=expr, =name) {}

    getType: func -> Type {
        ref ? ref type : null
    }

    toString: func -> String {
        name
    }

    resolve: func (task: Task) {
        marker : FuncDecl = null
        
        task walkBackward(|node|
            node resolveAccess(this, task, |var|
                ref = var
            )
            if(ref != null) return true // break if resolved
            
            // if still not resolved and was an anonymous function, mark the access
            if(!marker && node class == FuncDecl) {
                fd := node as FuncDecl
                if(fd anon?()) marker = fd
            }
            false
        )
        
        if(!ref) {
            "Undefined symbol `%s`" printfln(name)
            exit(1)
        }
        
        if(marker && !ref global) marker markAccess(this)
    }

}
