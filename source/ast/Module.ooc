
import structs/[ArrayList, List]

import middle/Resolver
import Node, FuncDecl, Call, Import, Scope

/**
 * A module contains types, functions, global variables.
 *
 * It has a name, a package, imports (ie. using another module's symbols)
 * uses (for native libraries)
 */
Module: class extends Node {

    /**
     * The fullname is somemthing like: "my/package/MyModule".
     * It doesn't contain ".ooc", and it's always '/', never '\' even
     * on win32 platforms.
     */
    fullName: String

    /** List of functions in thie module that don't belong to any type */
    body := Scope new()

    imports := ArrayList<Import> new()
    
    init: func (=fullName) {}


    resolve: func (task: Task) {
        task queue(body)
        task done()
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

}

