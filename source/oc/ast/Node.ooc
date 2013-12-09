
import oc/middle/Resolver
import Inquisitor

import Access, Var // for resolveAccess

Node: class {

    resolve: func (task: Task) {
        (task toString() + " node-stub, already done.") println()
    }

    toString: func -> String {
        class name
    }

    callResolver?: func -> Bool { false }

    accessResolver?: func -> Bool { false }

    resolveAccess: func (acc: Access, task: Task, suggest: Func (Var)) {
        // <your ad here>
    }

    surrender: func (inq: Inquisitor) {
        raise("#{class name} surrender(): stub!")
    }

}
