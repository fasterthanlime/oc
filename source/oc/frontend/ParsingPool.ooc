
// sdk
import threading/Thread
import structs/[List, ArrayList]
import os/[Time, System]

// ours
import oc/core/BuildParams
import oc/core/Plugins
import oc/frontend/Frontend
import oc/ast/[Module, Import]

/**
 * .ooc file that needs to be parsed
 */
ParsingJob: class {

    path: String
    module: Module
    _import: Import

    init: func (=path, =_import) {}

}

/**
 * Handles parallel parsing of .ooc files
 */
ParsingPool: class {

    todo := ArrayList<ParsingJob> new()
    done := ArrayList<ParsingJob> new()
    workers := ArrayList<ParserWorker> new()

    params: BuildParams
    factory: FrontendFactory

    active := true

    doneMutex, todoMutex: Mutex

    init: func (=params) {
        doneMutex = Mutex new()
        todoMutex = Mutex new()
        factory = Plugins loadFrontend(params frontendString)
        if(!factory) {
            "Couldn't load frontend #{params frontendString}, bailing out" println()
            exit(1)
        }
        factory setup(this)
    }

    push: func (j: ParsingJob) {
        todoMutex lock()
        todo add(j)
        todoMutex unlock()
    }

    done: func (j: ParsingJob) {
        doneMutex lock()
        done add(j)
        doneMutex unlock()
    }

    pop: func -> ParsingJob {
        job: ParsingJob = null
        todoMutex lock()
        if(todo size > 0) {
            job = todo removeAt(0)
        } else {
            stillActive := false
            workers each(|worker|
                if(worker busy) {
                    // still might have a chance of getting an import
                    stillActive = true
                }
            )
            active = stillActive
        }
        todoMutex unlock()
        job
    }

    exhaust: func {
        active = true
        numCores := numProcessors()
        for(i in 0..(numCores + 1)) {
            worker := ParserWorker new(this). run()
            workers add(worker)
        }

        while (active) {
            Time sleepMilli(10)
        }
    }

}

/**
 * Worker thread able to parse modules from a parsing job pool.
 */
ParserWorker: class {

    idSeed : static Int = 0
    id: Int
    busy := false
    pool: ParsingPool

    init: func (=pool) {
        idSeed += 1
        id = idSeed
    }

    run: func {
        Thread new(||
            //"Born [%d]" printfln(id)

            while (pool active) {
                job := pool pop()
                if(job) {
                    busy = true
                    if (pool params verbose > 1) "Parsing #{job path} [#{id}]" println()
                    builder := pool factory create()
                    builder parse(job path)
                    job module = builder module
                    if(job _import) job _import module = builder module
                    pool done(job)
                    busy = false
                } else {
                    Time sleepMilli(10)
                }
            }

            //"Dying [%d]" printfln(id)
        ) start()
    }

}

