
// sdk
import structs/[ArrayList, HashMap]

// ours
import backend/Backend
import frontend/BuildParams

import frontend/[ParsingPool, Frontend]

// enabled backends
import oc/backend/c89/c89glue
import oc/backend/pseudo/pseudoglue
import oc/frontend/nagaqueen/nqglue

Plugins: class {

    frontends := HashMap<String, FrontendFactory> new()
    backends := HashMap<String, Backend> new()

    instance: static This

    get: static func -> This {
        if (!instance) {
            instance = new()
        }
        instance
    }

    init: func

    registerFrontend: static func (name: String, factory: FrontendFactory) {
        get() frontends put(name, factory)
    }

    registerBackend: static func (name: String, backend: Backend) {
        get() backends put(name, backend)
    }

    loadFrontend: static func (name: String) -> FrontendFactory {
        res := get() frontends get(name)
        if (!res) {
            "Couldn't find frontend '#{name}'" println()
        }
        res
    }

    loadBackend: static func (name: String) -> Backend {
        res := get() backends get(name)
        if (!res) {
            "Couldn't find backend '#{name}'" println()
        }
        res
    }

}

