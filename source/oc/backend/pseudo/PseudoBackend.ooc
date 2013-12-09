use oc

// sdk
import structs/[HashMap, ArrayList, List]

// ours
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

PseudoGenerator: class {

    module: Module
    params: BuildParams

    map := HashMap<Class, CallBack> new()

    init: func (=module, =params) {
        // setup hooks
        put(CoverDecl,  |cd| visitCoverDecl(cd as CoverDecl))
        put(FuncDecl,   |fd| visitFuncDecl(fd as FuncDecl))
        put(Var,        |v|  visitVar(v as Var))
        put(Scope,      |s|  visitScope(s as Scope))
        put(Call,       |c|  visitCall(c as Call))
        put(BaseType,   |bt| visitBaseType(bt as BaseType))
        put(Access,     |a|  visitAccess(a as Access))
        put(NumberLit,  |nl| visitNumberLit(nl as NumberLit))

        "-------------------------------------------------" println()
        visitModule(module)
        "-------------------------------------------------" println()
    }

    put: func (T: Class, f: Func (Node)) {
        map put(T, CallBack new(f))
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
        visitNode(v type)
        if (v expr) {
            " = " print()
            visitNode(v expr)
        }
    }

    visitCoverDecl: func (cd: CoverDecl) {
        "cover #{cd name}" println()
        visitScope(cd body)	
    }

    visitNode: func (n: Node) {
        if (!n) {
            "(nil)" print()
            return
        }
        cb := map get(n class)
        if(cb) {
            cb f(n)
        } else {
            err("Unsupported node type: #{n class name}")
        }
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

    visitBaseType: func (bt: BaseType) {
        bt name print()
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
