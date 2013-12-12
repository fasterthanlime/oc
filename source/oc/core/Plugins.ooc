
// sdk
import structs/[ArrayList, HashMap]

// ours
import oc/core/BuildParams
import oc/frontend/Frontend
import oc/backend/Backend

// enabled backends
import oc/backend/c89/c89glue
import oc/backend/pseudo/pseudoglue
import oc/frontend/nagaqueen/nqglue

/**
 * Ideally, plug-ins would be loaded as dynamic libraries,
 * as it was once in oc. Nowadays it's mostly just 'packages'
 * which register themselves.
 *
 * Front-ends handle the "source code => AST" side of things.
 * Back-ends handle the "AST => compiler object" part of thing,
 * where a compiler object might be some sort of library or
 * executable, and where a backend might use some sort of
 * intermediary representation.
 */
Plugins: class {

    frontends := HashMap<String, FrontendFactory> new()
    backends := HashMap<String, Backend> new()

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

    /*
     * Private stuff (mostly shingleton (sic.) pattern).
     */

    instance: static This

    get: static func -> This {
        if (!instance) {
            instance = new()
        }
        instance
    }

}

