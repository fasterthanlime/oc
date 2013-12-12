
// sdk
import structs/[ArrayList, HashMap]

// ours
import oc/middle/Resolver

import Inquisitor
import Symbol, Node, Statement, Var, Access

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

    findSym: func (name: String, task: Task, suggest: Func (Symbol) -> Bool) -> Bool {
        "#{this} findSym(#{name}, ...)" println()

        if (!symbols) {
            return false
        }

        sym := symbols get(name)

        if (sym) {
            if (task has("noindex")) {
                // all good
            } else {
                idx := -1

                previous := task
                task walkBackwardTasks(|t|
                    if (t node == this) {
                        "walked backward to find #{this}, found previous #{previous}" println()
                        idx = previous get("index", Int)
                        return true
                    }
                    previous = t
                    false
                )
                if (idx < sym index) {
                    "> #{idx} < #{sym index}, not visible at this point in scope" println()
                    // not found, don't resolve
                    return false
                }
            }

            if (suggest(sym sym)) return true
        }

        false
    }

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

