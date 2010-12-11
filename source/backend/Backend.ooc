import ast/Module, frontend/BuildParams

Backend: abstract class {
    
    process: abstract func (module: Module, params: BuildParams)
    
}
