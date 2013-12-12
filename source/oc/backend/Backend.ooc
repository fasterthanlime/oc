
// ours
import oc/ast/[Module, Access, Var]
import oc/middle/Resolver
import oc/core/BuildParams

/**
 * Interface for pluggable backends in oc
 */
Backend: abstract class {
    
    /**
     * Given the full AST of a module and a set of build parameters, process
     * should compile the AST into the desired result.
     * 
     * A C backend might produce C files, then call a C compiler to produce
     * a library/executable, for instance.
     * 
     * A bytecode backend might produce backend and save it in files.
     * 
     * An interpreter backend might simply interpret the module.
     */
    process: abstract func (module: Module, params: BuildParams)
    
    /**
     * Override this method to have a backend-specific way to resolve variable
     * accesses.
     * 
     * For example, a C backend might automatically be aware of C types from
     * parsing header files, and allow resolving of those names automatically.
     */
    resolveAccess: func (acc: Access, task: Task, suggest: Func (Var)) {
        "resolveAccess(%s) in %s" printfln(acc toString(), class name)
    }

}
