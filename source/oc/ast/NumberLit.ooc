
import Expression, Type
import middle/Resolver

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

    init: func (=format, =value) {
        type = BaseType new("int") // well, maybe
    }

    resolve: func (task: Task) {
        task queue(type)
    }

    getType: func -> Type { type }

    intValue: func -> LLong {
        value toLLong(format as Int)
    }

    toString: func -> String {
        value
    }

}
