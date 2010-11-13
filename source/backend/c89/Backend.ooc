
import ast/[Module, Node, FuncDecl, Access, Var, Scope, Type,
    Call, StringLit, Statement, Expression]
import text/EscapeSequence

import structs/[HashMap, ArrayList, List]
import io/[File, FileWriter]

import C89Ast, StackBackend

CallBack: class {
    f: Func (Node) -> Object

    init: func (=f) {}
}

Backend: class extends StackBackend {

    module: Module
    source: CSource
    
    map := HashMap<Class, CallBack> new()

    init: func (=module) {
        source = CSource new(module fullName)
    	push(source)
        
        put(Call, |c| visitCall(c as Call))
        put(Var,  |v| visitVar(v as Var))
        put(StringLit, |sl| visitStringLit(sl as StringLit))
        
    	visitModule(module)
    }
    
    visitModule: func (m: Module) {
        ("Visiting module " + m fullName) println()
        loadFunc := CFunction new(type("void"), m fullName replaceAll("/", "_"))
        source functions add(loadFunc)
        loadFunc body addAll(visitScope(m body))
        
        main : CFunction = null
        for(f in source functions) {
            if(f name == "main") {
                main = f
                break
            }
        }
        if(!main) {
            main = CFunction new(type("int"), "main")
            main args add(var(type("int"), "argc")).
                      add(var(type("char**"), "argv"))
            source functions add(main)
            main body add(CReturn new(int(0)))
        }
        main body add(0, call(loadFunc name))
    }
    
    visitCall: func(c: Call) -> CStatement {
        "Visiting call %s" printfln(c toString())
        match (c subject) {
            case acc: Access =>
                "Got call to %s" printfln(acc name)
                cc := CCall new(acc name) // TODO: args
                c args each(|x| cc args add(visitExpr(x)))
                cc
            case =>
                "Call to whatever" println()
                Exception new("Unknown call subject type = " + c subject class name) throw(); null
        }
    }
    
    visitVar: func (v: Var) -> CStatement {
        match (v expr) {
            case null =>    	           
                return var(ctype(v type), v name)
            case fd: FuncDecl =>
                if(!fd externName) {
                    cf := CFunction new(ctype(fd retType), v name)
                    cf body addAll(visitScope(fd body))
                    source functions add(cf)
                }
            case =>
	            cv := var(ctype(v type), v name)
	            cv expr = visitExpr(v expr)
                return cv
        }
        nop
	}
    
    visitStringLit: func (s: StringLit) -> CStringLiteral {
        str(EscapeSequence unescape(s value))
    }
    
    visitScope: func (s: Scope) -> ArrayList<CStatement> {
        body := ArrayList<CStatement> new()
	    s body each(|stat|
            cstat := visitStat(stat)
	        if(!cstat instanceOf?(CNop)) body add(cstat)
	    )
        body
	}
    
    ctype: func (t: Type) -> CType {
        match t {
            case b: BaseType =>
                type(b name)
            case =>
                Exception new("Unknown type " + t toString() + ", assuming void") throw()
                null
        }
    }

    put: func (T: Class, f: Func (Node)) {
        map put(T, CallBack new(f))
    }
    
    visitStat: func (s: Statement) -> CStatement {
        cb := map get(s class)
        if(cb) {
            cstat := cb f(s)
            ("Visited stat " + s toString() + " of type " + s class name + ", cb f = %p, cstat address = %p") printfln(cstat, cb f as Closure thunk)
            (" got cstat " + cstat class name) println()
            return cstat as CStatement
        } else {
            Exception new("Unknown statement type %s" format(s class name)) throw()
        }
    }
    
    visitExpr: func (e: Expression) -> CExpr {
        "Visiting expr %s of type %s" printfln(e toString(), e class name)
        cb := map get(e class)
        if(cb) {
            return cb f(e) as CExpr
        } else {
            Exception new("Unknown expr type %s" format(e class name)) throw()
        }
    }
    
    visit: func (n: Node) {
        cb := map get(n class)
        if(cb) {
            cb f(n)
        } else {
            "Unknown node type %s" printfln(n class name)
        }
    }

    generate: func {
        peek(CSource) write("oc_tmp")
    }

}



