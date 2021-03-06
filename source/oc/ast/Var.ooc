
// ours
import oc/middle/Resolver

import Inquisitor
import Node, Symbol, Type, Expression

Var: class extends Expression {

    global := false

    _type: Type
    name: String { get set }
    expr: Expression { get set }

    init: func (=name) {}

    setType: func (=_type) {}

    getType: func -> Type {
        _type
    }

    resolve: func (task: Task) {
        if(!_type) {
            if(!expr)
                Exception new("Can't infer type of " + toString() + ", null expr") throw()
            task queue(expr)
            _type = expr getType()
            if(!_type)
                Exception new("Couldn't infer type of " + toString()) throw()
        }

        task queue(type)
    }

    toString: func -> String {
        name + (type ? ": " + type toString() : " :") + (expr ? "= " + expr toString() : "")
    }

    surrender: func (inq: Inquisitor) {
        inq visitVar(this)
    }

    symbol: func -> Symbol {
        (name, this) as Symbol
    }

}
