
import structs/ArrayList
import frontend/ParsingPool
import middle/Resolver
import backend/c89/C89Backend
import text/Opts

main: func (args: ArrayList<String>) {

    opts := Opts new(args)

    if(opts args size <= 1) {
        "Usage: oc file.ooc" println()
        exit(1)
    }
    
    opts args each(|arg|
        compile(arg, opts)
    )
    
}

compile: func (file: String, opts: Opts) {
    
    pool := ParsingPool new()
    mainJob := ParsingJob new(file, null)
    pool push(mainJob)
    pool exhaust()
    mainJob module main? = true

    Resolver new(C89Backend new(), mainJob module) start()
    
}
