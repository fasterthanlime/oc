
use libuse

// sdk
import io/File
import os/Coro

// ours
import oc/core/[BuildParams, Driver]

// third
import libuse/UseFile

/**
 * A compilation job
 */
CompileJob: class {

    parentCoro: Coro
    params: BuildParams
    useFile: File
    file: File

    init: func (=params, =parentCoro, arg: String) {
        isUse := false

        path := match {
            case arg endsWith?(".ooc") =>
                // good
                arg
            case arg endsWith?(".use") =>
                // good
                isUse = true
                arg
            case =>
                arg + ".ooc"
        }

        file = File new(path)
        if (!file exists?()) {
            "#{file path} not found, bailing out" println()
            exit(1)
        }

        if (isUse) {
            useFile = UseFile new(file)
            exit(1)
        }
    }

    launch: func {
        Driver compile(file path, params, parentCoro)
    }

}

