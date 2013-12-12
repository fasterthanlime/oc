
use oc, libovum

// sdk
import structs/[HashMap, ArrayList, List]
import io/BufferWriter

// ours
import oc/core/BuildParams
import oc/ast/[Inquisitor]
import oc/ast/[Module, Node, FuncDecl, Access, Var, Scope, Type,
       Call, StringLit, NumberLit, Statement, Expression, Return, CoverDecl]
import oc/middle/Resolver
import oc/backend/Backend

// third
import ovum/OWriter

/**
 * This backend outputs very simple pseudo-code: probably
 * useful to debug compiler bugs at various stages
 */

PseudoGenerator: class extends Inquisitor {

    module: Module
    params: BuildParams

    buffer := Buffer new()
    dw: OWriter

    init: func (=module, =params) {
        // use an OWriter, because it's awesome and does tabbing
        dw = OWriter new(BufferWriter new(buffer))

        dw app("-------------------------------------------------"). nl()
        visitModule(module)
        dw app("-------------------------------------------------"). nl()

        // actually print it
        buffer toString() println()
    }

    visitModule: func (m: Module) {
        dw app("module #{m fullName} ")
        visitScope(m body)
        dw nl()
    }

    visitScope: func (s: Scope) {
        if (s body empty?()) {
            dw app("{}")
            return
        }

        dw writeBlock(s body, "", |stat|
            visitNode(stat)
        )
    }

    visitVar: func (v: Var) {
        dw app(v name). app(": ")
        visitType(v type)
        if (v expr) {
            dw app(" = ")
            visitNode(v expr)
        }
    }

    visitCoverDecl: func (cd: CoverDecl) {
        dw app("cover "). app(cd name)
        visitScope(cd body)	
    }

    visitFuncDecl: func (fd: FuncDecl) {
        if (fd name && !fd name empty?()) {
            dw app(fd name). app(": ")
        }
        if (fd externName) {
            dw app("extern ")
            if (!fd externName empty?()) {
                dw app("("). app(fd externName). app(")")
            }
        }

        dw app("func ")
        if (!fd args empty?()) {
                dw writeEach(fd args, "(", ", ", ") ", |name, var|
                visitNode(var)
            )
        }
        visitNode(fd body)
        dw nl()
    }

    visitCall: func (c: Call) {
        visitNode(c subject)

        dw writeEach(c args, "(", ", ", ") ", |arg|
            visitNode(arg)
        )
    }

    visitType: func (t: Type) {
        match t {
            case null =>
                dw app("(null type)")
            case bt: BaseType =>
                dw app(bt name)
            case vt: VoidType =>
                dw app("void")
            case ft: FuncType =>
                dw app("Func ")
                dw writeEach(ft proto args, "(", ", ", ")", |name, arg|
                    visitType(arg type)
                )
                dw app(" -> ")
                visitType(ft proto retType)
            case =>
                err("Unsupported type kind: #{t class name}")
        }
    }

    visitAccess: func (a: Access) {
        if (a expr) {
            visitNode(a expr)
            dw app(" ")
        }
        dw app(a name)
    }

    visitNumberLit: func (nl: NumberLit) {
        dw app(nl value)
    }

    // private stuff

    err: func (msg: String) {
        "[pseudo backend] #{msg}" println()
    }

}

/**
 * The actual 'backend implementation' for oc
 */
pseudo_Backend: class extends Backend {

    init: func

    process: func (module: Module, params: BuildParams) {
        PseudoGenerator new(module, params)	
    }

}
