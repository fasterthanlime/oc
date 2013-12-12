

import oc/middle/Resolver
import Inquisitor
import Symbol, Expression, Type, Var, Node, Scope, Statement, FuncDecl

Access: class extends Expression {

    name: String
    expr: Expression

    sym: Symbol

    init: func (=expr, =name) {}

    getType: func -> Type {
        sym ref ? sym ref type : null
    }

    toString: func -> String {
        (expr ? expr toString() + " " : "") + name
    }

    resolve: func (task: Task) {
        marker: FuncDecl = null

        if(expr) task queue(expr)

        "Resolving access #{this}" println()
        task walkBackward(|node|
            //"Resolving access %s, in node %s" printfln(toString(), node toString())
            res := node findSym(name, task, |_sym|
                sym = _sym
                true
            )
            if (res) {
                return true // break if resolved
            }

            // if still not resolved and was a function, mark the access
            if(!marker && node class == FuncDecl) {
                fd := node as FuncDecl
                if(fd anon?()) marker = fd
            }
            false
        )

        if(!sym ref) {
            "Undefined symbol `%s`" printfln(name)
            exit(1)
        }

        /*
        if(marker && !sym ref global) marker markAccess(this)
        */
    }

    surrender: func (inq: Inquisitor) {
        inq visitAccess(this)
    }

}

