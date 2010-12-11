
import structs/[ArrayList, HashMap]

import backend/[Backend, BackendFactory]

BuildParams: class {
    
    VERSION := static "0.0"
    
    self := ""
    verbose := 0
    leftOver: HashMap<String, String>
    
    sourcepath := ["."] as ArrayList<String>
    outpath := "oc_tmp"
    
    backend: Backend = null
    
    init: func (map: HashMap<String, String>) {
        map each(|key, val| match key {
            case "sourcepath" =>
                sourcepath = val
            case "outpath" =>
                outpath = val
            case "backend" =>
                backend = BackendFactory make(val)
            case "v" || "verbose" =>
                verbose += 1
            case "V" =>
                "oc v%s - huhu" printfln(VERSION)
                exit(0)
            case "self" =>
                self = val
            case =>
                "Unknown option '%s', DO YOU KNOW THINGS THAT WE DON'T?" printfln(key)
                leftOver put(key, val)
        })
        
        if(!backend) {
            if(verbose > 0) "No backend selected, using C89 backend" println()
            backend = BackendFactory make("c89")
            if(!backend) {
                "Couldn't load c89 backend, bailing out!" println()
                exit(1)
            }
        }
        if(verbose > 0) {
            "oc v%s  sourcepath = %s  outpath = %s  backend is %s" printfln(VERSION, sourcepath join(":"), outpath, backend class name)
            "-----------------------------------------------------------------------"
        }
    }
    
}
