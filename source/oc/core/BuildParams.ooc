
// sdk
import io/File, os/Env, text/StringTokenizer
import structs/[ArrayList, HashMap]
import os/Coro

// ours
import oc/backend/Backend
import oc/Plugins

/**
 * Build parameters
 */
BuildParams: class {

    self := ""
    home := "."
    verbose := 0
    dump? := false
    leftOver: HashMap<String, String>

    sourcepath := ArrayList<String> new()
    outpath := "oc_tmp"

    backend: Backend { get set }
    backendString := ""
    frontendString := ""

    specialTask := SpecialTask NONE

    init: func {
        sourcepath add(".")
    }

}

/** Stuff the compiler can do besides compile */
SpecialTask: enum {
    NONE
    VERSION
    CLEAN
}

/**
 * Parse params from opts map
 */
ParamsParser: class {

    params: BuildParams

    init: func (=params, map: HashMap<String, String>) {
        map each(|key, val| match key {
            case "sourcepath" =>
                raise("sourcepath option not exactly supported yet")
                //sourcepath = val
            case "outpath" =>
                params outpath = val
            case "frontend" =>
                params frontendString = val
            case "backend" =>
                params backendString = val
            case "dump" =>
                params dump? = true
            case "v" || "verbose" =>
                params verbose += 1
            case "V" =>
                params specialTask = SpecialTask VERSION
            case "x" =>
                params specialTask = SpecialTask CLEAN
            case "self" =>
                params self = val
            case =>
                "Unknown option '#{key}', DO YOU KNOW THINGS THAT WE DON'T?" println()
                params leftOver put(key, val)
        })

        locateHome()

        if(params backendString == "") {
            if(params verbose > 0) "No backend selected, using C89 backend" println()
            params backendString = "c89"
        }

        if(params frontendString == "") {
            if(params verbose > 0) "No frontend selected, using nagaqueen backend" println()
            params frontendString = "nagaqueen"
        }

    }

    locateHome: func {
        if(params verbose > 0) "Should locate position of oc. Self = %s" printfln(params self)
        selfFile := File new(params self)

        if(selfFile exists?()) {
            // okay so we have a direct path to the exec - let's back out of bin/
            guess1 := selfFile getAbsoluteFile() parent parent
            if(params verbose > 0) "Guess from direct path is %s" printfln(guess1 path)
            params home = guess1 path
            return
        }

        // hmm let's search the path then
        path := Env get("PATH")
        if(path) {
            path split(File pathDelimiter) each(|folder|
                if(params verbose > 0) "Looking in %s" printfln(folder)
                // whoever thought of adding '.exe' to executable files wasn't in his right mind -.-
                f := File new(folder, params self)
                if(!f exists?()) {
                    f = File new(folder, params self + ".exe")
                    if(!f exists?()) return
                }

                guess2 := f getAbsoluteFile() parent parent
                if(params verbose > 0) "Guess from binary path is %s" printfln(guess2 path)
                params home = guess2 path
            )
        }
    }

}

