
import Statement, Expression

import middle/Resolver

Return: class extends Statement {

    expr: Expression { get set }

    init: func (=expr) {}

    resolve: func (task: Task) {
        if(expr) task queue(expr)
    }

    toString: func -> String {
        expr ? "return " + expr toString() : "return"
    }

}
