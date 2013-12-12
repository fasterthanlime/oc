
// sdk
import structs/[ArrayList, HashMap]

// ours
import oc/middle/Resolver

import Inquisitor
import Expression, Node, Statement, Var, Access

/**
 * Any block (list of nodes), really.
 */
Scope: class extends Node {

    body: ArrayList<Statement> { get set }
    symbols: HashMap<String, ScopeSymbol>

    init: func {
        body = ArrayList<Statement> new()
    }

    resolve: func (task: Task) {
        max := body size
        nodes := body data as Node*
        for (i in 0..max) {
            node := nodes[i]
            sym := node symbol()
            // if sym name is non-null, this is a symbol
            if (sym name) {
                if (!symbols) symbols = HashMap<String, ScopeSymbol> new()
                symbols put(sym name, ScopeSymbol new(i, sym))
            }
        }

        if (symbols) {
            symbols each(|name, symbol|
                "Got sym #{symbol}" println()
            )
        } else {
            "No symbols!" println()
        }

        task queueList(body)
    }

    resolveAccess: func (acc: Access, task: Task, suggest: Func (Var)) {
        if (!symbols) return

        sym := symbols get(acc name)

        if (sym) {
            if (task has("noindex")) {
                // all good
            } else {
                idx := -1

                previous := task
                task walkBackwardTasks(|t|
                    if (t node == this) {
                        idx = previous get("index", Int)
                        return true
                    }
                    previous = t
                    false
                )
                if (idx < sym index) {
                    "> #{idx} < #{sym index}, not visible at this point in scope" println()
                    return // not found, don't resolve
                }
            }

            ref := sym sym ref
            match ref {
                // ideally, suggest would accept anything, as we don't want to
                // only resolve accesses, but calls, etc.
                case var: Var =>
                    suggest(var)
            }
        }
    }

    /*
    resolveAccess: func (acc: Access, task: Task, suggest: Func (Var)) {
        idx := -1
        //"Looking for %s in %s" printfln(acc toString(), toString())

        if(task has("noindex")) {
            size := body size
            idx = size - 1
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
            if(idx == -1) {
                return // not found, don't resolve
            }
        }

        // idx + 1 to allow calling self
        nodes := body data as Node*

        limit := idx + 1
        for(i in 0..limit) {
            node := nodes[i]
            match (node class) {
                case Var =>
                    v := node as Var
                    if(v name == acc name) {
                        suggest(v)
                    }
            }
        }
    }
    */

    accessResolver?: func -> Bool { true }

    add: func (s: Statement) {
        body add(s)
    }

    toString: func -> String {
        "{ #{body size} elems }"
    }

    surrender: func (inq: Inquisitor) {
        inq visitScope(this)
    }

}

ScopeSymbol: class {

    index: Int
    sym: Symbol

    init: func (=index, =sym)

    toString: func -> String {
        "#{sym name} || #{sym ref} at #{index}"
    }

}

