
import structs/[List, ArrayList]

import middle/Resolver
import Statement, FuncDecl, Expression, Access

Call: class extends Statement {

    subject: Access { get set }
    args: List<Expression> { get set }
    
    ref: Expression

    init: func (=subject) {
        args = ArrayList<Expression> new()
    }

    resolve: func (task: Task) {
        task queueList(args)
        task queue(subject)
    }

    toString: func -> String {
        subject toString() + "()"
    }

}
