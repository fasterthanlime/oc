
import io/File

import oc/middle/Resolver
import oc/ast/Module
import oc/Plugins
import oc/frontend/[ParsingPool, BuildParams]

Driver: class {

    compile: static func (file: String, params: BuildParams) {

        if(!File new(file) exists?()) {
            "File not found: %s, bailing out" printfln(file)
            exit(1)
        }

        // parse main module and dependencies!
        pool := ParsingPool new(params)
        mainJob := ParsingJob new(file, null)
        pool push(mainJob)
        pool exhaust()

        if(params dump?) {
            pseudoBackend := Plugins loadBackend("pseudo")
            pool done each(|j| 
                pseudoBackend process(j module, params)
            )
        }

        params backend = Plugins loadBackend(params backendString)

        mainJob module main? = true
        Resolver new(params, mainJob module) start()

    }

}
