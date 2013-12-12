
// sdk
import structs/[ArrayList, HashMap]

// ours
import oc/middle/Resolver

import Inquisitor
import Node, Symbol, Expression, Statement, Scope, Var, Type, Access, Return, Call

FuncDecl: class extends Expression {

    global := false

    resolved := false
    body := Scope new()
    args := HashMap<String, Var> new()

    retType: Type { get set }
    _type: FuncType

    externName: String { get set }
    name: String { get set }

    // for closures
    accesses: ArrayList<Access>

    init: func ~fDecl {
        name = ""
        externName = null
        _type = FuncType new(this)
        retType = VoidType new()
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
                "Parent of #{this} is call #{c}" println()
                task queue(c subject)
                task need(|| c subject type != null)
                "Can finally infer type!" println()
                inferType(c)
        }

        autoReturn(task)
    }

    inferType: func (outerCall: Call) {
        "outerCall = #{outerCall}" println()

        // idx is our position in the call arguments, or -1 if we're not an argument of outerCall
        idx := outerCall args indexOf(this)
        if(idx == -1) {
            "Decl #{this} is a child of task for call #{outerCall} but it's not in its arguments!" println()
            return
        }
        "idx = #{idx}" println()

        // callRef is the Var that our outer call's subject has been resolved to
        callRef := outerCall subject sym ref
        if(!callRef getType() instanceOf?(FuncType)) {
            raise("Should never happen: outer call #{outerCall} was resolved to something \
                that's not a function! (ie. #{callRef getType()})")
        }
        "callRef = #{callRef}" println()

        // callProto is the FuncDecl which defines the argument types of the reference of the outer call
        callProto := callRef getType() as FuncType proto
        "callProto = #{callRef}" println()

        // outerType is the type that the outer call expects us to be. Our actual type is getType()
        outerType := callProto args get(callProto args getKeys() get(idx)) getType()
        if(!outerType instanceOf?(FuncType)) {
            raise("Passing a function (ie. #{this}) to a #{callProto} where expecting a #{outerType} (#{outerType class name})")
        }
        "outerType = #{outerType}" println()

        outerProto := outerType as FuncType proto
        "outerProto = #{outerProto}" println()

        if(outerProto args size != args size) {
            raise("Function #{this} is not compatible with type #{outerProto}")
        }

        "Inferring return type of #{this} to be #{retType}" println()
        retType = outerProto retType
    }

    autoReturn: func (task: Task) {
        if(!retType void?()) {
            list := body body
            if(list empty?()) {
                raise("Expected return expression in non-void function #{name}")
            } else {
                last := list last()
                if(last class == Return) {
                    // all good
                } else if(last instanceOf?(Expression)) {
                    list set(list size - 1, Return new(last as Expression))
                } else {
                    raise("Expected return expression in non-void function #{name}")
                }
            }
        }
    }

    findSym: func (name: String, task: Task, suggest: Func (Symbol) -> Bool) -> Bool {
        v := args get(name)
        if(v) {
            return suggest(v symbol())
        }
        false
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

    symbol: func -> Symbol {
        (name, this) as Symbol
    }

}
