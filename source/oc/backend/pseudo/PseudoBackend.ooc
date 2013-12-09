use oc

// sdk
import structs/[HashMap, ArrayList, List]

// ours
import oc/ast/[Inquisitor]
import oc/ast/[Module, Node, FuncDecl, Access, Var, Scope, Type,
       Call, StringLit, NumberLit, Statement, Expression, Return, CoverDecl]
import oc/middle/Resolver
import oc/frontend/BuildParams
import oc/backend/Backend

/**
 * This backend outputs very simple pseudo-code: probably
 * useful to debug compiler bugs at various stages
 */

CallBack: class {
    f: Func (Node)

    init: func(=f) {}
}

pseudo_Backend: class extends Backend {

    init: func

    process: func (module: Module, params: BuildParams) {
        PseudoGenerator new(module, params)	
    }

}

PseudoGenerator: class extends Inquisitor {

    module: Module
    params: BuildParams

    init: func (=module, =params) {
        "-------------------------------------------------" println()
        visitModule(module)
        "-------------------------------------------------" println()
    }

    visitModule: func (m: Module) {
        "module #{m fullName}" println()

        visitScope(m body)
    }

    visitScope: func (s: Scope) {
        if (s body empty?()) {
            "{}" print()
            return
        }

        "{" println()
        s body each(|stat|
            visitNode(stat)
            println()
        )
        "}" println()
    }

    visitVar: func (v: Var) {
        "#{v name}: " print()
        visitType(v type)
        if (v expr) {
            " = " print()
            visitNode(v expr)
        }
    }

    visitCoverDecl: func (cd: CoverDecl) {
        "cover #{cd name}" println()
        visitScope(cd body)	
    }

    visitFuncDecl: func (fd: FuncDecl) {
        if (fd name && !fd name empty?()) {
            fd name print()
            ": " print()
        }
        if (fd externName) {
            "extern " print()
            if (!fd externName empty?()) {
                "(" print()
                fd externName print()
                ") " print()
            }
        }
        "func (" print()
        fd args each(|name, var|
            visitNode(var)
            ", " print()
        )
        ") " print()
        visitNode(fd body)
        println()
    }

    visitCall: func (c: Call) {
        visitNode(c subject)
        "(" print()
        c args each(|arg|
            visitNode(arg)
            ", " print()
        )
        ")" print()
    }

    visitType: func (t: Type) {
        match t {
            case null =>
                "(null type)" println()
            case bt: BaseType =>
                bt name print()
            case vt: VoidType =>
                "void" print()
            case =>
                err("Unsupported type kind: #{t class name}")
        }
    }

    visitAccess: func (a: Access) {
        if (a expr) {
            visitNode(a expr)
            " " print()
        }
        a name print()
    }

    visitNumberLit: func (nl: NumberLit) {
        nl value print()
    }

    // private stuff

    err: func (msg: String) {
        "[pseudo backend] #{msg}" println()
    }

}
