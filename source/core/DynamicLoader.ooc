
import io/File

import backend/Backend
import frontend/BuildParams

import frontend/[ParsingPool, Frontend]

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
    
    findPlugin: func (name: String, callback: Func (LibHandle)) {
        plugins getChildren() each(|child|
            if(child name() startsWith?(prefix)) {
                if(params verbose > 0) "Found plug-in %s in %s" printfln(name, child path)
                
                handle := dlopen(child path, RTLD_LAZY)
                if(handle) {
                    callback(handle)
                } else {
                    "Error while opening plug-in %s: %s" printfln(path, dlerror())
                }
            } else {
                if(params verbose > 0) "Ignoring %s" printfln(child path)
            }
        )
    }
    
    loadBackend: static func (name: String, params: BuildParams) -> Backend {
        backend: Backend = null
        findPlugin(name + "_backend", |handle|
            classPrefix := "backend_%s_Backend_" format(name)
        
            // call load
            loadAddress := dlsym(handle, classPrefix + "load")
            if(!loadAddress) {
                "Symbol '%s' not found in %s" printfln(classPrefix + "load", name)
                dlclose(handle)
                return null
            }
            
            callableLoad: Closure 
            callableLoad thunk = loadAddress
            (callableLoad as Func)()
            
            // call constructor
            constructorAddress := dlsym(handle, classPrefix + "Backend_new")
            if(!constructorAddress) {
                "Symbol '%s' not found in %s" printfln(constructorSymbolName, name)
                dlclose(handle)
                return null
            }
            
            callableConstructor: Closure
            callableConstructor thunk = constructorAddress
            
            backend = (callableConstructor as Func -> Backend)()
            if(!backend) {
                "Couldn't instantiate backend for '%s', please report this bug to backend maintainers" printfln(name)
            }
            if(params verbose > 0) "Got backend %s" printfln(backend class name)
        )
        backend
    }
    
    loadFrontend: static func (name: String, pool: ParsingPool) -> FrontendFactory {
        factory: FrontendFactory = null
        findPlugin(name + "_frontend", |handle|
            classPrefix := "frontend_%s_FrontendFactory_" format(name)
        
            // call load
            loadAddress := dlsym(handle, classPrefix + "load")
            if(!loadAddress) {
                "Symbol '%s' not found in %s" printfln(classPrefix + "load", name)
                dlclose(handle)
                return null
            }
            
            callableLoad: Closure 
            callableLoad thunk = loadAddress
            (callableLoad as Func)()
            
            // call constructor
            constructorAddress := dlsym(handle, classPrefix + "FrontendFactory_new")
            if(!constructorAddress) {
                "Symbol '%s' not found in %s" printfln(constructorSymbolName, name)
                dlclose(handle)
                return null
            }
            
            callableConstructor: Closure
            callableConstructor thunk = constructorAddress
            
            factory = (callableConstructor as Func -> FrontendFactory)()
            if(!factory) {
                "Couldn't instantiate frontend for '%s', please report this bug to frontend maintainers" printfln(name)
            }
            if(params verbose > 0) "Got frontend %s" printfln(factory class name)
        )
        factory
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
