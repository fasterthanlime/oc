
// sdk
import structs/ArrayList
import text/Opts
import os/Coro
import io/File

// ours
import oc/core/[BuildParams, CompileJob]

/**
 * The core of the oc compiler
 */
Core: class {

    OC_VERSION := static "0.2.1"

    mainCoro, motherCoro: Coro
    opts: Opts
    params := BuildParams new()

    init: func (mainArgs: ArrayList<String>) {
        mainCoro = Coro new()
        mainCoro initializeMainCoro()

        opts = Opts new(mainArgs)
        ParamsParser new(params, opts opts)

        motherCoro = Coro new()
        mainCoro startCoro(motherCoro, ||
            work()
            exit(0)
        )
    }

    work: func {
        match (params specialTask) {
            case SpecialTask VERSION =>
                doVersion()
                exit(0)
            case SpecialTask CLEAN =>
                doClean()
                exit(0)
        }

        if(opts args empty?()) {
            doUsage()
            exit(1)
        }
        
        opts args each(|arg|
            compileArg(arg)
        )
    }

    doUsage: func {
        doVersion()
        "Usage: oc FILE" println()
        "Where FILE is a .use file or an .ooc file" println()
        "If no file is specified, the first .use file found will be compiled." println()
    }

    doClean: func {
        out := File new(params outpath)
        out rm_rf()
    }

    doVersion: func {
        "oc v%s - built on %s" printfln(OC_VERSION, __BUILD_DATETIME__)
        exit(0)
    }

    compileArg: func (arg: String) {
        job := CompileJob new(params, motherCoro, arg)
        job launch()
    }
}

