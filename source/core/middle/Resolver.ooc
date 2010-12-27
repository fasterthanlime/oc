
import os/Coro, structs/[ArrayList, List, Stack, HashBag]

import ast/[Node, Module]
import ../backend/Backend
import ../frontend/BuildParams

Task: class {
    resolver: Resolver
    
    id: Int { get set }
    idSeed := static 0

    parent: Task
    parentCoro, coro: Coro

    oldStackBase: Pointer
    
    node: Node { get set }
    done?: Bool { get set }
    
    userdata: HashBag

    lastFree := static Stack<This> new()

    init: func ~real (=parent, .node, dummy: Bool) {
        init(parent resolver, parent coro, node)
    }

    init: func ~onlyCoro (=resolver, =parentCoro, =node) {
        idSeed += 1
        id = idSeed
        coro = Coro new()
        done? = false
        version(OOC_TASK_DEBUG) { "Creating new task %s" printfln(toString()) }
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
    
    /**
     * Set userdata to this task
     */
    set: func <T> (key: String, value: T) {
        if(!userdata) userdata = HashBag new()
        userdata put(key, value)
    }
    
    unset: func (key: String) {
        if(!userdata) return
        userdata remove(key)
    }
    
    has: func (key: String) -> Bool {
        if(!userdata) return false
        userdata contains?(key)
    }
    
    get: func <T> (key: String, T: Class) -> T {
        if(userdata) {
            return userdata get(key, T)
        } else null
    }

    start: func {
        version(OOC_TASK_DEBUG) { (toString() + " started") println() }
        
        // Adjust the stackbottom and add our Coro's stack as a root for the GC
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

    queueList: func (l: Iterable<Node>) {
        pool := ArrayList<Node> new()
        l each(|n, i| spawn(n, i, pool))
        exhaust(pool)
    }

    queueAll: func (f: Func (Func (Node, Int))) {
        pool := ArrayList<Node> new()
        f(|n, i| spawn(n, i, pool))
        exhaust(pool)
    }

    spawn: func (n: Node, index: Int, pool: List<Task>) {
        version(OOC_TASK_DEBUG) {  (toString() + " spawning for " + n toString()) }
        task := Task new(this, n)
        task set("index", index)
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
        coro switchTo(task coro)
    }

    toString: func -> String {
        "[#%d %s]" format(id, node ? node toString() : "<no node>")
    }

    walkBackward: func (f: Func (Node) -> Bool) {
        if(f(node)) return // true = break
        if(parent)
            parent walkBackward(f)
    }
    
    walkBackwardTasks: func ~withTask (f: Func (Task) -> Bool) {
        if(f(this)) return // true = break
        if(parent)
            parent walkBackwardTasks(f)
    }
}

ModuleTask: class extends Node {
    module: Module
    
    init: func (=module) {}
    
    resolve: func (task: Task) {
        task queue(module)
        "Finished resolving %s!" printfln(module fullName)
        task resolver params backend process(module, task resolver params)
    }
}

Resolver: class extends Node {

    modules: ArrayList<Module> { get set }
    params: BuildParams

    init: func (=params, mainModule: Module) {
        modules = ArrayList<Module> new()
        modules addAll(mainModule getDeps())
    }

    start: func {
        "Resolver started, with %d module(s)!" printfln(modules size)

        mainCoro := Coro new()
        mainCoro initializeMainCoro()

        mainTask := Task new(this, mainCoro, this)
        mainTask start()
        while(!mainTask done?) {
            "" println()
            "========================== Looping! ===============" println()
            "" println()
            
            mainCoro switchTo(mainTask coro)
        }
    }

    resolve: func (task: Task) {
        task queueList(modules map(|m| ModuleTask new(m)))
    }

}
