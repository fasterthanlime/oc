
// sdk
import structs/[ArrayList, HashMap]

// ours
import oc/middle/Resolver

import Node, Symbol, Expression, Scope, Type, Call

CoverDecl: class extends Expression {

    body := Scope new()
    _type: Type

    resolved := false // artificial testing

    name: String { get set }

    init: func ~_cover {
        name = ""
        // type?
    }

    resolve: func (task: Task) {
        resolved = true // artificial testing
        task queue(body)
    }

    toString: func -> String {
        "cover " + body toString()
    }

    getType: func -> Type {
        _type
    }

    symbol: func -> Symbol {
        (name, this) as Symbol
    }

}
