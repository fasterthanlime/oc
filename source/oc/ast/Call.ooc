
import structs/[List, ArrayList]

import oc/middle/Resolver

import Inquisitor
import Symbol, FuncDecl, Expression, Access, Type

Call: class extends Expression {

    subject: Access
    args: List<Expression>

    init: func (=subject) {
        args = ArrayList<Expression> new()
    }

    resolve: func (task: Task) {
        task queueList(args)
        task queue(subject)
    }

    toString: func -> String {
        subject toString() + "(" + args map(|x| x toString()) join(", ") + ")"
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

    surrender: func (inq: Inquisitor) {
        inq visitCall(this)
    }

}
