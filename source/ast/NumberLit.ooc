
import nagaqueen/OocListener // for IntFormat
import Expression, Type
import middle/Resolver

NumberLit: class extends Expression {

    format: IntFormat
    value: String
    type := static BaseType new("int") // well, maybe

    init: func (=format, =value) {}

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
