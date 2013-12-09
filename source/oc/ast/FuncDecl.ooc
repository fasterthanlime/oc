
import structs/[ArrayList, HashMap]

import oc/middle/Resolver

import Inquisitor
import Expression, Statement, Scope, Var, Type, Access, Return, Call

FuncDecl: class extends Expression {

    global := false

    resolved := false
    body := Scope new()
    args := HashMap<String, Var> new()

    retType := VoidType new()
    _type: FuncType

    externName: String { get set }
    name: String { get set }

    // for closures
    accesses: ArrayList<Access>

    init: func ~fDecl {
        name = ""
        externName = null
        _type = FuncType new(this)
    }

    anon?: func -> Bool {
        name empty?()
    }

    markAccess: func (acc: Access) {
        if(!accesses) {
            accesses = ArrayList<Access> new()
        } else {
            for(acc2 in accesses) {
                if(acc name == acc2 name) return
            }
        }
        "%s is accessing %s" printfln(toString(), acc toString())
        accesses add(acc)
    }

    resolve: func (task: Task) {
        task queueList(args)
        task queue(retType)
        resolved = true // artificial testing

        task queue(body)

        match (task parent node) {
            case c: Call =>
                "Parent of %s is call %s" printfln(toString(), c toString())
                while(c subject ref == null) {
                    "ref = %s" printfln(c subject ref ? c subject ref toString() : "(nil)")
                    "C subject's ref is null, yielding" println()
                    task parent queue(c subject)
                    "Back here!" println()
                }
                inferType(c)
        }

        autoReturn(task)
    }

    inferType: func (outerCall: Call) {
        "outerCall = %s" printfln(outerCall toString())

        // idx is our position in the call arguments, or -1 if we're not an argument of outerCall
        idx := outerCall args indexOf(this)
        if(idx == -1) {
            "Decl %s is a child of task for call %s but it's not in its arguments!" printfln(toString(), outerCall toString())
            return
        }
        "idx = %d" printfln(idx)

        // callRef is the Var that our outer call's subject has been resolved to
        callRef := outerCall subject ref
        if(!callRef getType() instanceOf?(FuncType)) {
            Exception new("Should never happen: outer call %s was resolved to something that's not a function! (ie. %s)" \
                format(outerCall toString(), callRef getType() toString())) throw()
        }
        "callRef = %s" printfln(callRef toString())

        // callProto is the FuncDecl which defines the argument types of the reference of the outer call
        callProto := callRef getType() as FuncType proto
        "callProto = %s" printfln(callRef toString())

        // outerType is the type that the outer call expects us to be. Our actual type is getType()
        outerType := callProto args get(callProto args getKeys() get(idx)) getType()
        if(!outerType instanceOf?(FuncType)) {
            Exception new("Passing a function (ie. %s) to a %s where expecting a %s (%s)" format(toString(), callProto toString(), outerType toString(), outerType class name)) throw()
        }
        "outerType = %s" printfln(outerType toString())

        outerProto := outerType as FuncType proto
        "outerProto = %s" printfln(outerProto toString())

        if(outerProto args size != args size) {
            Exception new("Function %s is not compatible with type %s" format(toString(), outerProto toString())) throw()
        }

        "Inferring return type of %s to be %s" printfln(toString(), outerProto retType toString())
        retType = outerProto retType
    }

    autoReturn: func (task: Task) {
        if(!retType void?()) {
            list := body body
            if(list empty?()) {
                "Expected return expression in non-void function %s" printfln(name)
                exit(1)
            } else {
                last := list last()
                if(last class == Return) {
                    // all good
                } else if(last instanceOf?(Expression)) {
                    list set(list size - 1, Return new(last as Expression))
                } else {
                    "Expected return expression in non-void function %s" printfln(name)
                    exit(1)
                }
            }
        }
    }

    resolveAccess: func (acc: Access, task: Task, suggest: Func (Var)) {
        v := args get(acc name)
        if(v) suggest(v)
    }

    toString: func -> String {
        b := Buffer new()
        b append("func (")
        first := true
        for(arg in args) {
            if(first) first = false
            else      b append(", ")
            b append(arg toString())
        }
        b append(") -> ")
        b append(retType toString())
        b toString()
    }

    getType: func -> Type {
        _type
    }

    surrender: func (inq: Inquisitor) {
        inq visitFuncDecl(this)
    }

}
