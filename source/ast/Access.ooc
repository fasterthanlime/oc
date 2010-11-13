

import middle/Resolver
import Expression, Type, Var, Node, Scope, Statement

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
        task walkBackward(|node|
            node resolveAccess(this, task, |var|
                ref = var
            )
            (ref != null) // break if resolved
        )
        
        if(!ref)
            Exception new("Undefined symbol `" + name + "`") throw()
    }

}
