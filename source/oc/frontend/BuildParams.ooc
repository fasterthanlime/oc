
import io/File, os/Env, text/StringTokenizer
import structs/[ArrayList, HashMap]

import oc/backend/Backend
import oc/DynamicLoader

BUILD_DATE: extern CString

BuildParams: class {

    VERSION := static "0.0"

    self := ""
    home := "."
    verbose := 0
    dump? := false
    leftOver: HashMap<String, String>

    sourcepath := ArrayList<String> new()
    outpath := "oc_tmp"

    backend: Backend = null
    backendString := ""
    frontendString := ""

    init: func (map: HashMap<String, String>) {
        sourcepath add(".")

        map each(|key, val| match key {
            case "sourcepath" =>
                raise("sourcepath option not exactly supported yet")
                //sourcepath = val
            case "outpath" =>
                outpath = val
            case "frontend" =>
                frontendString = val
            case "backend" =>
                backendString = val
            case "dump" =>
                dump? = true
            case "v" || "verbose" =>
                verbose += 1
            case "V" =>
                "oc v%s - built on %s" printfln(VERSION, __BUILD_DATETIME__)
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

        if(frontendString == "") {
            if(verbose > 0) "No frontend selected, using nagaqueen backend" println()
            frontendString = "nagaqueen"
        }
    }

    locateHome: func {
        if(verbose > 0) "Should locate position of oc. Self = %s" printfln(self)
        selfFile := File new(self)

        if(selfFile exists?()) {
            // okay so we have a direct path to the exec - let's back out of bin/
            guess1 := selfFile getAbsoluteFile() parent parent
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

                guess2 := f getAbsoluteFile() parent parent
                if(verbose > 0) "Guess from binary path is %s" printfln(guess2 path)
                home = guess2 path
            )
        }
    }

}
