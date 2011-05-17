
import ParsingPool
import ast/Module

/**
 * Interface for pluggable frontends
 */
Frontend: abstract class {
    
    module: Module
    pool: ParsingPool
    
    /**
     * Create a new frontend, able to parse .ooc files, attached to a given
     * ParsingPool. The pool is used to trigger the parsing of imported .ooc
     * files
     */
    init: func (=pool) {}
    
    /**
     * Given the path to an .ooc file, the frontend should parse it and produce
     * an AST for the module. It can trigger the parsing of imported .ooc files
     * using pool push()
     */
    parse: abstract func (path: String)
    
}

FrontendFactory: abstract class {
    
    init: func (pool: ParsingPool) {}
    
    create: abstract func -> Frontend
    
}
