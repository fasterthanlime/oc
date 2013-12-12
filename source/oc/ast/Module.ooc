
// sdk
import structs/[ArrayList, List]

// urs
import oc/middle/Resolver
import Node, Symbol, Import, Scope

/**
 * A module contains types, functions, global variables.
 *
 * It has a name, a package, imports (ie. using another module's symbols)
 * uses (for native libraries)
 */
Module: class extends Node {

    /**
     * The fullname is something like: "my/package/MyModule".
     * It doesn't contain ".ooc", and it's always '/', never '\' even
     * on win32 platforms.
     */
    fullName: String

    body := Scope new()

    imports := ArrayList<Import> new()
    includes := ArrayList<String> new()

    main? : Bool { get set }

    init: func (=fullName)

    resolve: func (task: Task) {
        task queue(body)
    }

    getDeps: func (list := ArrayList<Module> new()) -> List<Module> {
        list add(this)
        imports each(|i|
            if(!list contains?(i module)) {
                i module getDeps(list)
            }
        )
        list
    }

    findSym: func (name: String, task: Task, suggest: Func (Symbol) -> Bool) -> Bool {
        "findSym(#{name}, ...) in #{this}, with #{imports size} import, task is #{task}" println()

        task set("noindex", true)
        for(imp in imports) {
            res := imp module body findSym(name, task, suggest)
            if (res) return true
        }
        task unset("noindex")

        // still not resolved?
        task resolver params backend findSym(name, task, suggest)

        false
    }

    toString: func -> String {
        "module " + fullName
    }

}
