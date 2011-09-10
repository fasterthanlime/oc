
import io/File, os/Env, text/StringTokenizer
import structs/[ArrayList, HashMap]

import backend/Backend
import DynamicLoader

BUILD_DATE: extern CString

BuildParams: class {
    
    VERSION := static "0.0"
    
    self := ""
    home := "."
    verbose := 0
    dump? := false
    leftOver: HashMap<String, String>
    
    sourcepath := ["."] as ArrayList<String>
    outpath := "oc_tmp"
    
    backend: Backend = null
    backendString := ""
    
    init: func (map: HashMap<String, String>) {
        
        map each(|key, val| match key {
            case "sourcepath" =>
                sourcepath = val
            case "outpath" =>
                outpath = val
            case "backend" =>
                backendString = val
	    case "dump" =>
		dump? = true
            case "v" || "verbose" =>
                verbose += 1
            case "V" =>
                "oc v%s - built on %s" printfln(VERSION, BUILD_DATE)
                exit(0)
            case "self" =>
                self = val
            case =>
                "Unknown option '%s', DO YOU KNOW THINGS THAT WE DON'T?" printfln(key)
                leftOver put(key, val)
        })
        
        locateHome()
        
        if(backendString == "") {
            if(verbose > 0) "No backend selected, using C89 backend" println()
            backendString = "c89"
        }
    }
    
    locateHome: func {
        if(verbose > 0) "Should locate position of oc. Self = %s" printfln(self)
        selfFile := File new(self)
        
        if(selfFile exists?()) {
            // okay so we have a direct path to the exec - let's back out of bin/
            guess1 := selfFile getAbsoluteFile() parent() parent()
            if(verbose > 0) "Guess from direct path is %s" printfln(guess1 path)
            home = guess1 path
            return
        }
        
        // hmm let's search the path then
        path := Env get("PATH")
        if(path) {
            path split(File pathDelimiter) each(|folder|
                if(verbose > 0) "Looking in %s" printfln(folder)
                // whoever thought of adding '.exe' to executable files wasn't in his right mind -.-
                f := File new(folder, self)
                if(!f exists?()) {
                    f = File new(folder, self + ".exe")
                    if(!f exists?()) return
                }
                
                guess2 := f getAbsoluteFile() parent() parent()
                if(verbose > 0) "Guess from binary path is %s" printfln(guess2 path)
                home = guess2 path
            )
        }
    }
    
}
