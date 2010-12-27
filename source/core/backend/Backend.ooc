import ast/[Module, Access, Var]
import middle/Resolver
import frontend/BuildParams

Backend: abstract class {
    
    process: abstract func (module: Module, params: BuildParams)
    
    resolveAccess: func (acc: Access, task: Task, suggest: Func (Var)) {
        "resolveAccess(%s) in %s" printfln(acc toString(), class name)
    }
    
}
