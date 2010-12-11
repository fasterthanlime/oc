
import structs/ArrayList
import frontend/[ParsingPool, BuildParams]
import middle/Resolver
import backend/BackendFactory
import text/Opts

main: func (args: ArrayList<String>) {

    opts := Opts new(args)

    params := BuildParams new(opts opts)
    if(opts args empty?()) {
        "Usage: oc file.ooc" println()
        exit(1)
    }
    
    opts args each(|arg|
        compile(arg, params)
    )
    
}

compile: func (file: String, params: BuildParams) {

    // parse main module and dependencies!
    pool := ParsingPool new()
    mainJob := ParsingJob new(file, null)
    pool push(mainJob)
    pool exhaust()
    
    mainJob module main? = true
    Resolver new(params, mainJob module) start()
    
    BackendFactory cleanup() // this isn't one of the bestest place to do that.
    
}
