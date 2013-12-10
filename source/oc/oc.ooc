
use oc

// sdk
import structs/ArrayList
import text/Opts
import os/Coro
import io/File

// ours
import oc/frontend/[BuildParams, Driver]
import oc/structs/NStructs

main: func (mainArgs: ArrayList<String>) {
    Oc new(mainArgs)
}

Oc: class {
    mainCoro: Coro
    opts: Opts
    params: BuildParams

    init: func (mainArgs: ArrayList<String>) {
        mainCoro = Coro new()
        mainCoro initializeMainCoro()

        opts = Opts new(mainArgs)
        params = BuildParams new(opts opts)

        if(opts args empty?()) {
            "Usage: oc FILE" println()
            "Where FILE is a .use file or an .ooc file" println()
            "If no file is specified, the first .use file found will be compiled." println()
            exit(1)
        }
        
        opts args each(|arg|
            compileArg(arg)
        )
    }

    compileArg: func (arg: String) {
        path := match {
            case arg endsWith?(".ooc") =>
                // TODO: prepare dummy use file and stuff
                arg
            case arg endsWith?(".use") =>
                raise("use compilation unsupported for now")
                null
            case =>
                arg + ".ooc"
        }

        file := File new(path)
        if (!file exists?()) {
            "#{file path} not found, bailing out" println()
            exit(1)
        }

        Driver compile(path, params, mainCoro)
    }
}

