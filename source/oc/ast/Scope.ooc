
import structs/[ArrayList, List]

import oc/middle/Resolver
import Node, Statement, Var, Access

Scope: class extends Node {

    body: List<Statement> { get set }

    init: func {
        body = ArrayList<Statement> new()
    }

    resolve: func (task: Task) {
        task queueList(body)
    }

    resolveAccess: func (acc: Access, task: Task, suggest: Func (Var)) {
        idx : Int = -1
        //"Looking for %s in %s" printfln(acc toString(), toString())

        if(task has("noindex")) {
            size := body size
            idx = size
        } else {
            previous := task
            task walkBackwardTasks(|t|
                if(t node == this) {
                    idx = previous get("index", Int)
                    return true
                }
                previous = t
                false
            )
            if(idx == -1) return // not found, don't resolve
        }
        
        // idx + 1 to allow recursion, of course :)
        for(i in 0..(idx + 1)) {
            node := body[i]
            match (node class) {
                case Var =>
                    v := node as Var
                    if(v name == acc name)
                        suggest(v)
            }
        }
    }

    accessResolver?: func -> Bool { true }

    add: func (s: Statement) {
        body add(s)
    }

    toString: func -> String {
        "{}"
    }

}
