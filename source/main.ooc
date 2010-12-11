
import structs/ArrayList
import frontend/[ParsingPool, BuildParams]
import middle/Resolver
import text/Opts

main: func (args: ArrayList<String>) {

    opts := Opts new(args)

    if(opts args empty?()) {
        "Usage: oc file.ooc" println()
        exit(1)
    }
    
    opts args each(|arg|
        compile(arg, opts)
    )
    
}

compile: func (file: String, opts: Opts) {

    params := BuildParams new(opts opts)

    pool := ParsingPool new()
    mainJob := ParsingJob new(file, null)
    pool push(mainJob)
    pool exhaust()
    mainJob module main? = true

    Resolver new(params, mainJob module) start()
    
}
