
import ast/[Module, Node, FuncDecl, Access, Var, Scope, Type,
    Call, StringLit, NumberLit, Statement, Expression, Return]
import text/EscapeSequence

import structs/[HashMap, ArrayList, List]
import io/[File, FileWriter]

import C89Ast, StackBackend

CallBack: class {
    f: Func (Node) -> Object

    init: func (=f) {}
}

C89Backend: class extends StackBackend {

    module: Module
    source: CSource
    
    map := HashMap<Class, CallBack> new()

    init: func {
        put(Call,  |c| visitCall(c as Call))
        put(Var,   |v| visitVar(v as Var))
        put(Access,|a| visitAccess(a as Access))
        put(Return,|r| visitReturn(r as Return))
        put(FuncDecl, |fd| visitFuncDecl(fd as FuncDecl))
        put(StringLit, |sl| visitStringLit(sl as StringLit))
        put(NumberLit, |sl| visitNumberLit(sl as NumberLit))
    }

    process: func (=module) {
        source = CSource new(module fullName)
        stack clear()
    	push(source)
        visitModule(module)
        peek(CSource) write("oc_tmp")
    }
    
    visitModule: func (m: Module) {
        ("Visiting module " + m fullName) println()
        loadFunc := CFunction new(type("void"), "__" + m fullName map(|c| c alphaNumeric?() ? c : '_') + "__")
        source functions add(loadFunc)
        
        visitScope(m body) each(|stat|
            if(stat class == CVariable && stat as CVariable shallow?) return
            loadFunc body add(stat)
        )
        
        if(m main?) {
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
    }
    
    visitReturn: func (r: Return) -> CReturn {
        CReturn new(r expr ? visitExpr(r expr) : null)
    }
    
    visitCall: func(c: Call) -> CStatement {
        match (c subject) {
            case acc: Access =>
                cc := CCall new(acc name) // TODO: args
                c args each(|x| cc args add(visitExpr(x)))
                cc
            case =>
                Exception new("Unknown call subject type = " + c subject class name) throw(); null
        }
    }
    
    visitVar: func (v: Var) -> CVariable {
        match (v expr) {
            case null =>    	           
                var(ctype(v type), v name)
            case =>
	            cv := var(ctype(v type), v name)
                push(cv)
	            cv expr = visitExpr(v expr)
                pop(CVariable)
        }
	}
    
    visitFuncDecl: func (fd: FuncDecl) -> CAccess {
        name := fd name
        if(name empty?()) {
            match (stack peek()) {
                case v: CVariable =>
                    name = v name
                    v shallow? = true
                case =>
                    // just generate a garbage name
                    name = stack peek() genName("anonfunc")
            }
        }
        
        visitFuncDeclWithName(fd, name)
    }
    
    visitFuncDeclWithName: func (fd: FuncDecl, name: String) -> CAccess {
        cf := CFunction new(ctype(fd retType), name)
        push(cf)
        fd args each(|arg| cf args add(visitVar(arg)))
        cf body addAll(visitScope(fd body))
        pop(CFunction)
        
        if(!fd externName) {
            source functions add(cf)
            if(fd accesses) {
                ctx := CStructDecl new(name + "__ctx")
                
                shim := CFunction new(cf returnType, name + "_shim")
                shim args addAll(cf args)
                ctxVar := var(ctx type pointer(), "__context__")
                shim args add(ctxVar)
                
                call := CCall new(name)
                
                fd accesses each(|acc|
                    v := visitVar(acc ref)
                    ctx elements add(v)
                    cf args add(v)
                    call args add(CAccess new(ctxVar acc() deref(), acc name))
                )
                shim body add(call)
                
                source types add(ctx)
                source functions add(shim)
                
                // use the shim's name as an access
                return acc(shim name)
            }
        }
        acc(name)
    }
    
    visitAccess: func (a: Access) -> CAccess {
        CAccess new(a expr ? visitExpr(a expr) : null, a name)
    }
    
    visitStringLit: func (s: StringLit) -> CStringLiteral {
        str(EscapeSequence unescape(s value))
    }
    
    visitNumberLit: func (n: NumberLit) -> CIntLiteral {
        CIntLiteral new(n value)
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
            case f: FuncType =>
                cf := CFuncType new(ctype(f proto retType))
                f proto args each(|arg| cf argTypes add(ctype(arg getType())))
                cf
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
            return cb f(s) as CStatement
        } else {
            Exception new("Unknown statement type %s" format(s class name)) throw()
        }
    }
    
    visitExpr: func (e: Expression) -> CExpr {
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

}
