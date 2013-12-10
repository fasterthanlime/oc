
use oc

// sdk
import structs/ArrayList
import text/Opts
import os/Coro

// ours
import oc/frontend/[BuildParams, Driver]
import oc/structs/NStructs

main: func (mainArgs: ArrayList<String>) {
    mainCoro := Coro new()
    mainCoro initializeMainCoro()

    opts := Opts new(mainArgs)
    params := BuildParams new(opts opts)

    if(opts args empty?()) {
        "Usage: oc file.ooc" println()
        exit(1)
    }
    
    opts args each(|arg|
        Driver compile(arg, params, mainCoro)
    )
    
}
