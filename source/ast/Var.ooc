

import middle/Resolver
import Type, Expression

Var: class extends Expression {

    _type: Type
    name: String { get set }
    expr: Expression { get set }

    init: func (=name) {}

    getType: func -> Type {
        _type
    }

    resolve: func (task: Task) {
        if(!_type) {
            task queue(expr)
            "expr = %p, class = %s" printfln(expr, expr class name)
            "and expr = %s" printfln(expr toString())
            _type = expr getType()
            if(!_type)
                Exception new("Couldn't resolve type of " + toString()) throw()
        }

        task queue(type)
    }

    toString: func -> String {
        name + (type ? ": " + type toString() : " :") + (expr ? "= " + expr toString() : "")
    }

}

