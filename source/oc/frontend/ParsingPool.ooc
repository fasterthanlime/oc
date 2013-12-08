
import Frontend, BuildParams

import oc/ast/[Module, Import]
import oc/middle/Resolver
import oc/DynamicLoader

import threading/Thread, structs/[List, ArrayList], os/[Time, System]

ParsingJob: class {

    path: String
    module: Module
    _import: Import

    init: func (=path, =_import) {}

}

ParsingPool: class {

    todo := ArrayList<ParsingJob> new()
    done := ArrayList<ParsingJob> new()
    workers := ArrayList<ParserWorker> new()
    
    factory: FrontendFactory

    active := true

    doneMutex, todoMutex: Mutex

    init: func (params: BuildParams) {
        doneMutex = Mutex new()
        todoMutex = Mutex new()
        factory = DynamicLoader loadFrontend(params frontendString, params, this)
        if(!factory) {
            fprintf(stderr, "Couldn't load frontend nagaqueen, bailing out\n")
            exit(1)
        }
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
                    "Parsing %s [%d]" printfln(job path, id)
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

