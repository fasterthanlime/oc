
// sdk
import os/Coro, structs/[ArrayList, List, Stack, HashBag]

// ours
import oc/ast/[Node, Module]
import oc/backend/Backend
import oc/core/BuildParams

/**
 * The whole resolution / desugaring / checking process
 * happens within Tasks in oc. Tasks are basically coroutines
 * on steroids - they can queue other tasks, wait for them,
 * in the order which a program requires.
 */
Task: class {
    resolver: Resolver

    id: Int
    idSeed := static 0

    parent: Task
    parentCoro, coro: Coro

    /** Node doing this task */
    node: Node

    // state

    done?: Bool
    userdata: HashBag

    // pool of recently finished tasks to be re-used
    // instead of creating new coroutines
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
    set: final func <T> (key: String, value: T) {
        if(!userdata) userdata = HashBag new()
        userdata put(key, value)
    }

    unset: final func (key: String) {
        if(!userdata) return
        userdata remove(key)
    }

    has: final func (key: String) -> Bool {
        if(!userdata) return false
        userdata contains?(key)
    }

    get: final func <T> (key: String, T: Class) -> T {
        if(userdata) {
            return userdata get(key, T)
        } else null
    }

    start: final func {
        version(OOC_TASK_DEBUG) { (toString() + " started") println() }

        parentCoro startCoro(coro, ||
            // This allows us to reuse tasks
            while (this node != null) {
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

    yield: final func {
        version(OOC_TASK_DEBUG) { (toString() + " yield") println() }
        coro switchTo(parentCoro)
    }

    queue: final func (n: Node) {
        task := Task new(this, n)
        version(OOC_TASK_DEBUG) { (toString() + " queuing " + n toString() + " with " + task toString()) println() }
        task start()
        while(!task done?) {
            version(OOC_TASK_DEBUG) { (task toString() + " not done yet, looping") println() }
            switchTo(task)
            yield()
        }
    }

    queueList: final func (l: Iterable<Node>) {
        pool := ArrayList<Task> new()
        l each(|n, i| spawn(n, i, pool))
        exhaust(pool)
    }

    queueAll: final func (f: Func (Func (Node, Int))) {
        pool := ArrayList<Task> new()
        f(|n, i| spawn(n, i, pool))
        exhaust(pool)
    }

    spawn: final func (n: Node, index: Int, pool: List<Task>) {
        version(OOC_TASK_DEBUG) {  (toString() + " spawning for " + n toString()) }
        task := Task new(this, n)
        task set("index", index)
        task start()
        if(!task done?) pool add(task)
    }

    exhaust: final func (pool: List<Task>) {
        version(OOC_TASK_DEBUG) { (toString() + " exhausting pool ") println() }

        nextPool := ArrayList<Task> new()
        while(!pool empty?()) {
            pool each(|task|
                version(OOC_TASK_DEBUG) {  (toString() + " switching to unfinished task " + task toString()) println() }
                switchTo(task)
                if(!task done?) {
                    nextPool add(task)
                }
            )

            if(!nextPool empty?()) {
                yield()
            }

            pool clear()
            (pool, nextPool) = (nextPool, pool)
        }
    }

    need: final func (f: Func -> Bool) {
        while(!f()) {
            yield()
        }
    }

    switchTo: final func (task: Task) {
        coro switchTo(task coro)
    }

    toString: func -> String {
        "[#%d %s]" format(id, node ? node toString() : "<no node>")
    }

    walkBackward: final func (f: Func (Node) -> Bool) {
        if(f(node)) return // true = break
        if(parent) {
            parent walkBackward(f)
        }
    }

    walkBackwardTasks: final func ~withTask (f: Func (Task) -> Bool) {
        if(f(this)) return // true = break
        if(parent) {
            parent walkBackwardTasks(f)
        }
    }
}

ModuleTask: class extends Node {
    module: Module

    init: func (=module)

    resolve: func (task: Task) {
        task queue(module)
        "Finished resolving %s!" printfln(module fullName)
        task resolver params backend process(module, task resolver params)
    }
}

/**
 * Special AST node whose purpose is to resolve all
 * nodes in our compile job.
 */
Resolver: class extends Node {

    modules: ArrayList<Module> { get set }
    params: BuildParams

    init: func (=params, mainModule: Module) {
        modules = ArrayList<Module> new()
        modules addAll(mainModule getDeps())
    }

    start: func (parentCoro: Coro) {
        "Resolving #{modules size} module(s)..." printfln(modules size)

        mainTask := Task new(this, parentCoro, this)
        mainTask start()
    }

    resolve: func (task: Task) {
        task queueList(modules map(|m| ModuleTask new(m)))
    }

}

