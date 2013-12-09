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

	"-------------------------------------------------" println()
	visitModule(module)
	"-------------------------------------------------" println()
    }

    put: func (T: Class, f: Func (Node)) {
	map put(T, CallBack new(f))
    }

    visitModule: func (m: Module) {
	("module " + m fullName) println()

	visitScope(m body)
    }

    visitScope: func (s: Scope) {
	"{" println()
	s body each(|stat| visitStat(stat))
	"}" println()
    }

    visitStat: func (s: Statement) {
	cb := map get(s class)
	if(cb) {
	    cb f(s)
	} else {
	    "Unsupported node type: %s" printfln(s class)
	}
    }

    visitCoverDecl: func (cd: CoverDecl) {
	"cover %s" printf(cd name)
	visitScope(cd body)	
    }

}
