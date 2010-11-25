
import frontend/ParsingPool
import middle/Resolver
import backend/c89/C89Backend

main: func (argc: Int, argv: CString*) {

    if(argc <= 1) {
        "Usage: oc file.ooc" println()
        exit(1)
    }
    
    pool := ParsingPool new()
    mainJob := ParsingJob new(argv[1] toString(), null)
    pool push(mainJob)
    pool exhaust()
    mainJob module main? = true

    Resolver new(C89Backend new(), mainJob module) start()
    
}
