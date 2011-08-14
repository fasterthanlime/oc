
import frontend/[ParsingPool, BuildParams]
import io/File
import middle/Resolver
import ast/Module

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

	if(params dump?) pool done each(|j| 
	    "--dump is enabled, here's the AST of %s" printfln(j module fullName)
	    "" println()
	    "================================================" printfln()
	    j module toString() println()
	    "================================================" printfln()
	    "" println()
	)
        
        mainJob module main? = true
        Resolver new(params, mainJob module) start()
        
    }
 
}
