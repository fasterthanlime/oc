
import os/Coro, structs/[ArrayList, List, Stack]

import ast/[Node, Module]
import backend/tree/Backend

Task: class {
    id: Int { get set }
    idSeed := static 0

    parent: Task
    parentCoro, coro: Coro

    oldStackBase: Pointer
    
    node: Node { get set }
    done?: Bool { get set }

    lastFree := static Stack<This> new()

    init: func ~real (=parent, .node, dummy: Bool) {
        init(parent coro, node)
    }

    init: func ~onlyCoro (=parentCoro, =node) {
        idSeed += 1
        id = idSeed
        coro = Coro new()
        done? = false
        version(OOC_TASK_DEBUG) { "Creating new task %s" printfln(toString() toCString()) }
    }

    new: static func (.parent, .node) -> This {
        if(lastFree empty?()) {
            new~real(parent, node, false)
        } else {
            res := lastFree pop()
            version(OOC_TASK_DEBUG) { ("Re-using last free task " + res toString()) println() }
            res parent = parent
            res node = node
            res done? = false
            res
        }
    }

    start: func {
        version(OOC_TASK_DEBUG) { (toString() + " started") println() }
        stackBase := coro stack
        stackSize := coro allocatedStackSize
        
        // Adjust the stackbottom and add our Coro's stack as a root for the GC
        GC_stackbottom = stackBase
        GC_add_roots   (stackBase, stackBase + stackSize)

        parentCoro startCoro(coro, ||
            // This allows us to reuse tasks
            while(this node != null) {
                version(OOC_TASK_DEBUG) { (toString() + " launching resolve of " + toString()) println() }
                this node resolve(this)
                version(OOC_TASK_DEBUG) { (toString() + " finished, yielding " + toString()) println() }
                this done? = true
                this node = null
                This lastFree push(this)
                yield()
            }
        )
    }

    yield: func {
        version(OOC_TASK_DEBUG) { (toString() + " yield") println() }
        GC_stackbottom = parentCoro stack
        
        coro switchTo(parentCoro)
    }

    queue: func (n: Node) {
        task := Task new(this, n)
        version(OOC_TASK_DEBUG) { (toString() + " queuing " + n toString() + " with " + task toString()) println() }
        task start()
        while(!task done?) {
            version(OOC_TASK_DEBUG) { (task toString() + " not done yet, looping") println() }
            switchTo(task)
            yield()
        }
    }

    queueList: func (l: List<Node>) {
        pool := ArrayList<Node> new()
        l each(|n| spawn(n, pool))
        exhaust(pool)
    }

    queueAll: func (f: Func (Func (Node))) {
        pool := ArrayList<Node> new()
        f(|n| spawn(n, pool))
        exhaust(pool)
    }

    spawn: func (n: Node, pool: List<Task>) {
        version(OOC_TASK_DEBUG) {  (toString() + " spawning for " + n toString()) }
        task := Task new(this, n)
        task start()
        if(!task done?) pool add(task)
    }

    exhaust: func (pool: List<Task>) {
        version(OOC_TASK_DEBUG) { (toString() + " exhausting pool ") println() }
        while(!pool empty?()) {
            oldPool := pool
            pool = ArrayList<Task> new()

            oldPool each(|task|
                version(OOC_TASK_DEBUG) {  (toString() + " switching to unfinished task " + task toString()) println() }
                switchTo(task)
                if(!task done?) pool add(task)
            )

            if(!pool empty?()) yield()
        }
    }

    need: func (f: Func -> Bool) {
        while(!f()) {
            yield()
        }
    }

    switchTo: func (task: Task) {
        GC_stackbottom = coro stack
        coro switchTo(task coro)
    }

    toString: func -> String {
        "[#%d %s]" format(id, node ? node toString() toCString() : "<no node>" toCString())
    }

    walkBackward: func (f: Func (Node) -> Bool) {
        if(f(node)) return // true = break
        if(parent)
            parent walkBackward(f)
    }
}

Resolver: class extends Node {

    modules: ArrayList<Module> { get set }

    init: func {
        modules = ArrayList<Module> new()
    }

    start: func {
        "Resolver started, with %d module(s)!" printfln(modules size)

        mainCoro := Coro new()
        mainCoro initializeMainCoro()

        mainTask := Task new(mainCoro, this)
        mainTask start()
        while(!mainTask done?) {
            "" println()
            "========================== Looping! ===============" println()
            "" println()
            
            mainCoro switchTo(mainTask coro)
        }
        "All done resolving!" println()
        "=================================" println()

        modules each(|module|
            b := Backend new(module)
            b generate()
        )
    }

    resolve: func (task: Task) {
        task queueAll(|queue|
            modules each(|m| queue(m))
        )
    }

}

