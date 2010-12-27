
import structs/[List, ArrayList]

import middle/Resolver
import FuncDecl, Expression, Access, Type

Call: class extends Expression {

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
    
    getType: func -> Type {
        sType := subject getType()
        if(sType) match (sType) {
            case ft: FuncType =>
                return ft proto retType
            case =>
                Exception new("Trying to call something that's not a function! " + sType toString())
        }
        null
    }

}
