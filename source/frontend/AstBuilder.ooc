use nagaqueen

import structs/Stack, io/File

import nagaqueen/OocListener

import ParsingPool

import ast/[Module, FuncDecl, Call, Statement, Type, Expression,
    Var, Access, StringLit, Import, Node]
import middle/Resolver

/**
 * Used to parse multi-vars declarations, ie.
 * 
 *   a, b, c: Int
 */
VarStack: class {

    type: Type
    vars := Stack<Var> new()

}

AstBuilder: class extends OocListener {

    module: Module
    stack := Stack<Object> new()

    pool: ParsingPool

    init: func (=pool) {}

    parse: func (path: String) {
        try {
            module = Module new(path substring(0, -5))
            stack push(module)
            super(path)
        } catch (e: Exception) {
            e print()
        }
    }

    /*
     * Stack handling functions
     */
    pop: func <T> (T: Class) -> T {
        v := stack pop()
        if(!v instanceOf?(T)) Exception new("Expected " + T name + ", pop'd " + v class name) throw()
        v
    }

    peek: func <T> (T: Class) -> T {
        v := stack peek()
        if(!v instanceOf?(T)) Exception new("Expected " + T name + ", peek'd " + v class name) throw()
        v
    }

    stackString: func -> String {
        b := Buffer new()
        stack each(|el|
            b append(match el {
                case n: Node => n toString()
                case         => el class name
            }). append("->")
        )
        b toString()
    }

    /*
     * Import
     */
    onImport: func (path, name: CString) {
        nullPath := (path == null || (path as Char*)[0] == '\0')
        importName := nullPath ? path toString() + name toString() : name toString()
        _import := Import new(importName)
        peek(Module) imports add(_import)

        // FIXME: this is a very very dumb strategy to get the real path of an Import
        // but oh well, I'm testing ParsingPool right now.
        realPath := File new(File new(module fullName) parent() path, importName) path + ".ooc"

        // FIXME: and what about caching? huh?
        pool push(ParsingJob new(realPath, _import))
    }

    /*
     * Functions
     */
    onFunctionStart: func (name, doc: CString) {
        fd := FuncDecl new()
        fd name = name toString()
        stack push(fd)
    }

    onFunctionEnd: func -> FuncDecl {
        fd := pop(FuncDecl)
        ("End of function, stack = " + stackString()) println()
        if(stack peek() instanceOf?(Module)) {
            var := Var new(fd name)
            fd name = ""
            var expr = fd
            onStatement(var)
        }
        fd
    }

    onFunctionArgsStart: func {
        stack push(peek(FuncDecl) args)
        
    }

    onFunctionArgsEnd: func {
        stack pop() // args
    }
    

    onFunctionBody: func {
        // ignore
    }

    onFunctionAttr: func (f: FuncAttributes, value: CString = null) {
        fd := peek(FuncDecl)
        match f {
            case FuncAttributes _extern =>
                fd externName = value toString()
            case =>
                "Unknown function attribute %d" printfln(f)
        }
    }

    onFunctionReturnType: func (returnType: Type) {
        peek(FuncDecl) retType = returnType
    }

    /*
     * Function calls
     */
    
    onFunctionCallStart: func (name: CString) {
        stack push(Call new(Access new(null, name toString())))
    }

    onFunctionCallArg: func (arg: Expression) {
        peek(Call) args add(arg)
    }

    onFunctionCallEnd: func -> Call {
        pop(Call)
    }

    /* Variable declarations */

    onVarDeclStart: func {
        stack push(VarStack new())
    }

    onVarDeclEnd: func -> Object {
        pop(VarStack)
    }


    onVarDeclName: func (name, doc: CString) {
        vStack := peek(VarStack)
        vStack vars push(Var new(name toString()))
    }

    onVarDeclExpr: func (expr: Expression) {
        peek(VarStack) vars peek() expr = expr
    }

    onVarDeclType: func (type: Type) {
        peek(VarStack) vars each(|v|
            v _type = type
        )
    }

    /* Types */

    onTypeNew: func (name: CString) -> Type {
        BaseType new(name toString())
    }

    /* Various expression/statements */
    
    onStringLiteral: func (text: CString) -> StringLit {
        StringLit new(text toString())
    }

    onVarAccess: func (expr: Expression, name: CString) -> Access {
        Access new(expr, name toString())
    }

    /*
     * Statement
     */
    onStatement: func (statement: Statement) {
        match statement {
            case vStack: VarStack =>
                vStack vars each(|v|
                    ("Popping var " + v toString())
                    onStatement(v)
                )
                return
        }
        
        node := stack peek()
        match node {
            case fd: FuncDecl =>
                //"Got statement %s in function %s" printfln(statement toString(), fd toString())
                fd body add(statement)
            case mod: Module =>
                "Got statement %s in module body" printfln(statement toString())
                mod body add(statement)
            case =>
                ("Don't know how to react to statement " + statement toString() +
                    " with " + node class name + " on top of the stack.") println()
        }
    }

}

