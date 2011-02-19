
import frontend/[ParsingPool, BuildParams]
import io/File
import middle/Resolver

Driver: class {
    
    compile: static func (file: String, params: BuildParams) {

	if(!File new(file) exists?()) {
	    "File not found: %s, bailing out" printfln(file)
	    exit(1)
	}

        // parse main module and dependencies!
        pool := ParsingPool new()
        mainJob := ParsingJob new(file, null)
        pool push(mainJob)
        pool exhaust()
        
        mainJob module main? = true
        Resolver new(params, mainJob module) start()
        
    }
 
}
