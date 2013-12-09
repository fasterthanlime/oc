
import Expression, Type
import oc/middle/Resolver

/** Different number formats - in sync with nagaqueen's "IntFormat" */
NumberFormat: enum {
    bin = 2
    oct = 8
    dec = 10
    hex = 16
}

NumberLit: class extends Expression {

    format: NumberFormat
    value: String

    _type := static BaseType new("int") // well, maybe

    init: func (=format, =value)

    resolve: func (task: Task) {
        task queue(type)
    }

    getType: func -> Type { _type }

    intValue: func -> LLong {
        value toLLong(format as Int)
    }

    toString: func -> String {
        value
    }

}
