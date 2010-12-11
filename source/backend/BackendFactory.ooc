import Backend
import io/File

BackendFactory: class {
    
    previousHandle: static LibHandle = null
    
    make: static func (name: String) -> Backend {
        if(previousHandle) {
            "Closing previous handle"
            dlclose(previousHandle)
        }
        
        prefix := name + "_backend"
        
        // TODO ohum: plugins is not necessarily in "./"
        plugins := File new("plugins")
        
        path := ""
        plugins getChildren() each(|child|
            if(child name() startsWith?(prefix)) {
                "Found backend %s in %s" printfln(child path, name)
                path = child path
            } else {
                "Ignoring %s" printfln(child path)
            }
        )
        
        if(!path empty?()) {
            handle := dlopen(path, RTLD_LAZY)
            
            if(!handle) {
                "Error while opening pluggable backend %s: %s" printfln(path, dlerror())
                return null
            }
            
            // that's the constructor we're looking for!
            symbolName := "backend_%s_Backend__%s_Backend_new" format(name, name)
            
            "Looking for symbol %s" printfln(symbolName)
            constructor := dlsym(handle, symbolName)
            
            "Got address %p" printfln(constructor)
            if(!constructor) {
                "Symbol '%s' not found in backend %s" printfln(symbolName, path)
                dlclose(handle)
                return null
            }
            
            callable: Func -> Backend
            callable as Closure thunk = constructor
            
            backend := callable()
            if(!backend) {
                "Couldn't instantiate backend for '%s', please report this bug to backend maintainers" printfln(name)
            }
            "Got backend %s" printfln(backend class name)
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
