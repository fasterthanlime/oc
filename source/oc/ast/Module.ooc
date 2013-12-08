
import structs/[ArrayList, List]

import oc/frontend/BuildParams
import oc/middle/Resolver
import Node, FuncDecl, Call, Import, Scope, Access, Var

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
    
    init: func (=fullName) {}


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
    
    resolveAccess: func (acc: Access, task: Task, suggest: Func (Var)) {
        //"Resolving %s in %s, with %d import, task is %s" printfln(acc toString(), toString(), imports size, task toString())
        
        task set("noindex", true)
        for(imp in imports) {
            imp module body resolveAccess(acc, task, suggest)
            if(acc ref) break
        }
        task unset("noindex")
        
        if(!acc ref) {
            // combo X5!
            task resolver params backend resolveAccess(acc, task, suggest)
        }
    }
    
    toString: func -> String {
        "module " + fullName
    }

}
