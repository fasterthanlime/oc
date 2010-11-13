
import structs/[ArrayList, List]

import middle/Resolver
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

        previous := task
        task walkBackwardTasks(|t|
            if(t node == this) {
                //"task has? %d previous has? %d" printfln(t has("index"), previous has("index"))
                idx = previous get("index", Int)
                //"Found index of %s in %s = %d" printfln(previous toString(), toString(), idx)
                return true
            }
            previous = t
            false
        )
        if(idx == -1) return // not found, don't resolve
        
        resolveAccess(acc, task, suggest, idx)
    }

    resolveAccess: func ~withIdx (acc: Access, task: Task, suggest: Func (Var), idx: Int) {
        for(i in 0..idx) {
            match (node := body[i]) {
                case v: Var =>
                    if(v name == acc name)
                        suggest(v)
            }
        }
    }

    accessResolver?: func -> Bool { true }

    add: func (s: Statement) {
        body add(s)
    }

}

