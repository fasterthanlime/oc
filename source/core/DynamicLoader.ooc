
import io/File

import backend/Backend
import frontend/BuildParams

DynamicLoader: class {
    
    plugins: static File

    init: static func (params: BuildParams) {
        plugins = File new(params home, "plugins")
        if(!plugins exists?()) {
            "Couldn't locate oc plugins in %s - please set the OC_DIST environment variable" printfln(plugins path)
            exit(1)
        }
        
        params backend = loadBackend(params backendString, params)
        if(!params backend) {
            "Couldn't load backend '%s', bailing out!" printfln(params backendString)
            exit(1)
        }
        
        if(params verbose > 0) {
            "oc v%s  sourcepath = %s  outpath = %s  backend is %s" printfln(params VERSION, params sourcepath join(":"), params outpath, params backend class name)
            "-----------------------------------------------------------------------"
        }
    }
    
    exit: static func {
        // So here's the fun thing: we can't unload core nor sdk
        // without making the application crash. However, simply exiting
        // seems to clean up stuff cleanly AND not crash!
        exit(0)
    }
    
    loadBackend: static func (name: String, params: BuildParams) -> Backend {
        prefix := name + "_backend"
        
        path := ""
        plugins getChildren() each(|child|
            if(child name() startsWith?(prefix)) {
                if(params verbose > 0) "Found backend %s in %s" printfln(child path, name)
                path = child path
            } else {
                if(params verbose > 0) "Ignoring %s" printfln(child path)
            }
        )
        
        if(!path empty?()) {
            handle := dlopen(path, RTLD_LAZY)
            
            if(!handle) {
                "Error while opening pluggable backend %s: %s" printfln(path, dlerror())
                return null
            }
            
            // call load
            loadSymbolName := "backend_%s_Backend_load" format(name)
            loadAddress := dlsym(handle, loadSymbolName)
            if(!loadAddress) {
                "Symbol '%s' not found in backend %s" printfln(loadSymbolName, path)
                dlclose(handle)
                return null
            }
            
            callableLoad: Closure 
            callableLoad thunk = loadAddress
            (callableLoad as Func)()
            
            // call constructor
            constructorSymbolName := "backend_%s_Backend__%s_Backend_new" format(name, name)
            constructorAddress := dlsym(handle, constructorSymbolName)
            if(!constructorAddress) {
                "Symbol '%s' not found in backend %s" printfln(constructorSymbolName, path)
                dlclose(handle)
                return null
            }
            
            callableConstructor: Closure
            callableConstructor thunk = constructorAddress
            
	    backend: Backend
	    backend = (callableConstructor as Func -> Backend)()
            if(!backend) {
                "Couldn't instantiate backend for '%s', please report this bug to backend maintainers" printfln(name)
            }
            if(params verbose > 0) "Got backend %s" printfln(backend class name)
            return backend
        }
        null
    }
    
}

/* C binding part */
use dl

LibHandle: cover from Pointer {}
RTLD_LAZY, RTLD_NOW, RTLD_GLOBAL: extern Int

dlopen  : extern func (fileName: CString, flag: Int) -> LibHandle
dlsym   : extern func (handle: LibHandle, symbolName: CString) -> Pointer
dlclose : extern func (handle: LibHandle) -> Int
dlerror : extern func -> CString
