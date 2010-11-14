
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
        //"Looking for %s in %s, initial index = %d" printfln(acc toString(), toString(), idx)

        if(task has("noindex")) {
            size := body size
            idx = size
        } else {
            previous := task
            task walkBackwardTasks(|t|
                if(t node == this) {
                    previous has("index")
                    //"task has? %d previous has? %d" printfln(t has("index"), previous has("index"))
                    idx = previous get("index", Int)
                    //"Found index of %s in %s = %d" printfln(previous toString(), toString(), idx)
                    return true
                }
                previous = t
                false
            )
            //"For access %s, found index of %s in %s = %d" printfln(acc toString(), previous toString(), toString(), idx)
            if(idx == -1) return // not found, don't resolve
        }
        
        for(i in 0..idx) {
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

}

