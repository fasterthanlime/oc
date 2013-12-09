
use oc

import structs/ArrayList
import text/Opts

import frontend/[BuildParams, Driver]

main: func (mainArgs: ArrayList<String>) {

    opts := Opts new(mainArgs)
    params := BuildParams new(opts opts)

    if(opts args empty?()) {
        "Usage: oc file.ooc" println()
        exit(1)
    }
    
    args := opts args
    args each(|arg|
        Driver compile(arg, params)
    )
    
}
