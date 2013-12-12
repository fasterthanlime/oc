
// ours
import oc/middle/Resolver
import Inquisitor
import Symbol

/**
 * Mother to all AST nodes
 */
Node: class {

    resolve: func (task: Task) {
        (task toString() + " node-stub, already done.") println()
    }

    toString: func -> String {
        class name
    }

    callResolver?: func -> Bool { false }

    findSym: func (name: String, task: Task, suggest: Func (Symbol) -> Bool) -> Bool {
        false
    }

    surrender: func (inq: Inquisitor) {
        raise("#{class name} surrender(): stub!")
    }

    symbol: func -> Symbol {
        (null, null) as Symbol
    }

}

