
import oc/middle/Resolver

import Inquisitor
import Statement, Expression

Return: class extends Statement {

    expr: Expression { get set }

    init: func (=expr) {}

    resolve: func (task: Task) {
        if(expr) task queue(expr)
    }

    toString: func -> String {
        expr ? "return " + expr toString() : "return"
    }

    surrender: func (inq: Inquisitor) {
        inq visitReturn(this)
    }

}
