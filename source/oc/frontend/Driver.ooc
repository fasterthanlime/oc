
// sdk
import io/File
import os/Coro

// ours
import oc/middle/Resolver
import oc/ast/Module
import oc/Plugins
import oc/frontend/[ParsingPool, BuildParams]

Driver: class {

    compile: static func (oocPath: String, params: BuildParams, parentCoro: Coro) {

        oocFile := File new(oocPath)
        if(!oocFile exists?()) {
            "File not found: #{oocPath}, bailing out" println()
            exit(1)
        }

        // parse main module and dependencies!
        pool := ParsingPool new(params)
        mainJob := ParsingJob new(oocPath, null)
        pool push(mainJob)
        pool exhaust()

        // load backend
        params backend = Plugins loadBackend(params backendString)

        // and start resolver
        mainJob module main? = true
        res := Resolver new(params, mainJob module)
        res start(parentCoro)

        // if -dump, load pseudo backend and run it
        if(params dump?) {
            pseudoBackend := Plugins loadBackend("pseudo")
            pool done each(|j| 
                pseudoBackend process(j module, params)
            )
        }

    }

}
