
import frontend/[ParsingPool, BuildParams]
import middle/Resolver

Driver: class {
    
    compile: static func (file: String, params: BuildParams) {

        // parse main module and dependencies!
        pool := ParsingPool new()
        mainJob := ParsingJob new(file, null)
        pool push(mainJob)
        pool exhaust()
        
        mainJob module main? = true
        Resolver new(params, mainJob module) start()
        
    }
 
}
