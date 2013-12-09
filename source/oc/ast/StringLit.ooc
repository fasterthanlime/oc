
import Expression, Type

import Inquisitor
import oc/middle/Resolver

StringLit: class extends Expression {

    value: String
    _type := static BaseType new("String")

    init: func (=value)

    resolve: func (task: Task) {
        task queue(type)
    }

    getType: func -> Type { _type }

    toString: func -> String {
        "\"" + value + "\""
    }

    surrender: func (inq: Inquisitor) {
        inq visitStringLit(this)
    }

}
