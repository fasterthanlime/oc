
import ast/[Module, Node, FuncDecl, Access, Var, Scope, Type,
    Call, StringLit, NumberLit, Statement, Expression, Return]
import text/[Opts, EscapeSequence]

import structs/[HashMap, ArrayList, List]
import io/[File, FileWriter]

import frontend/BuildParams
import C89Ast, StackGenerator, ../Backend

CallBack: class {
    f: Func (Node) -> Object

    init: func (=f) {}
}

C89Backend: class extends Backend {
    
    process: func (module: Module, params: BuildParams) {
        C89Generator new(module, params)
    }
    
}

C89Generator: class extends StackGenerator {

    module: Module
    source: CSource
    loadFunc: CFunction
    params: BuildParams
    
    map := HashMap<Class, CallBack> new()

    init: func(=module, =params) {
        // setup hooks
        put(Call,  |c| visitCall(c as Call))
        put(Var,   |v| visitVar(v as Var))
        put(Access,|a| visitAccess(a as Access))
        put(Return,|r| visitReturn(r as Return))
        put(FuncDecl,  |fd| visitFuncDecl(fd as FuncDecl))
        put(StringLit, |sl| visitStringLit(sl as StringLit))
        put(NumberLit, |sl| visitNumberLit(sl as NumberLit))
    
        // initialize the source and the stack
        source = CSource new(module fullName)
        push(source)
        visitModule(module)
        peek(CSource) write(params outpath)
    }
    
    visitModule: func (m: Module) {
        ("Visiting module " + m fullName) println()
        loadFunc = CFunction new(type("void"), "__" + m fullName map(|c| c alphaNumeric?() ? c : '_') + "__")
        source functions add(loadFunc)
        
        push(loadFunc)
        visitScope(m body) each(|stat|
            if(stat class == CVariable && stat as CVariable shallow?) return
            loadFunc body add(stat)
        )
        pop(CFunction)
        
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
                cc := CCall new(acc name)
                v := acc ref
                
                if(v expr) {
                    "Calling %s, acc ref is %s of type %s" printfln(acc name, v expr toString(), v expr class name)
                } else {
                    "Calling %s, acc ref is %s, no expr" printfln(acc name, acc ref toString())
                }
                if(!v expr || v expr class != FuncDecl) {
                    cc fat = true
                }
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
        anon := false
        if(name empty?()) {
            match (stack peek()) {
                case v: CVariable =>
                    name = v name
                    v shallow? = true
                case =>
                    // just generate a garbage name
                    name = stack peek() genName("anonfunc")
                    anon = true
            }
        }
        
        visitFuncDeclWithName(fd, name, anon)
    }
    
    visitFuncDeclWithName: func (fd: FuncDecl, name: String, anon: Bool) -> CAccess {
        cf := CFunction new(ctype(fd retType), name)
        push(cf)
        fd args each(|arg| cf args add(visitVar(arg)))
        cf body addAll(visitScope(fd body))
        pop(CFunction)
        
        if(!fd externName) {
            source functions add(cf)
        }
            
        // create the fat version of the func pointer
        fatPointer := CStructLiteral new(type("struct Closure"))
        fatVar := var(fatPointer type, name + "_fatPtr")
        fatVar expr = fatPointer
        
        // TODO: find a way to add fatVar to the body :x
        outer := find(CFunction)
        if(!outer) {
            "No outer context for closure with name %s" printfln(name)
            exit(1)
        }
        
        if(fd accesses) {
            ctx := CStructDecl new(name + "__ctx")
            
            shim := CFunction new(cf returnType, name + "_shim")
            shim args addAll(cf args)
            ctxVar := var(ctx type pointer(), name + "__context__")
            ctxLiteral := CStructLiteral new(ctx type)
            
            if(outer) {
                outer body add(acc("/* Yay memory leaks! */"))
                outer body add(assign(ctxVar, call("malloc", call("sizeof", acc("struct " + ctx name)))))
                outer body add(assign(acc(ctxVar name) deref(), ctxLiteral))
            }
            shim args add(ctxVar)
            
            call := CCall new(name)
            
            fd accesses each(|acc|
                v := visitVar(acc ref)
                ctx elements add(v)
                ctxLiteral elements add(CAccess new(null, acc name))
                cf args add(v)
                call args add(CAccess new(ctxVar acc() deref(), acc name))
            )
            shim body add(call)
            
            source types add(ctx)
            source functions add(shim)
            
            fatPointer elements add(acc(shim name))
            fatPointer elements add(acc(ctxVar name))
            
        } else {
            fatPointer elements add(acc(name))
            fatPointer elements add(acc("NULL"))
        }
        
        if(outer && (anon || fd accesses)) {
            outer body add(fatVar)
        }
        acc(fatVar name)
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
