import io/[File, FileWriter, OcWriter], structs/[List, ArrayList]
import text/EscapeSequence

/**
 * A source is a combination of .c/.h file
 */
CSource: class {

    name: String

    includes := ArrayList<String> new()

    functions := ArrayList<CFunction> new()
    types := ArrayList<CTypeDecl> new()

    init: func (=name) {}

    write: func (basePath: String) {
        baseFile := File new(basePath)
        if(!baseFile exists?()) baseFile mkdirs()
        hw := OcWriter new(FileWriter new(File new(baseFile, name + ".h")))

	    define := "__" + name toUpper() + "__define__"
	    hw nl(). app("#ifndef "). app(define)
	    hw nl(). app("#define "). app(define)

	    includes each(|i| hw nl(). app("#include "). app(i))

	    hw nl(). app("#endif")

        hw close()
        
        cw := OcWriter new(FileWriter new(File new(baseFile, name + ".c")))
        cw nl(). app("#include \""). app(name). app(".h\"")

        types     each(|t| t write(cw))
        functions each(|f| f write(cw))
        cw close()
    }

}

CFunction: class {

    returnType: CType
    name: String
    args := ArrayList<CVariable> new()
    body := ArrayList<CStatement> new()

    init: func (=returnType, =name) {}

    write: func (w: OcWriter) {
    	w nl(). nl()
        returnType write(w)
        w app(" "). app(name)
        w writeEach(args, "(", ", ", ") ", |arg| arg write(w))
        w writeBlock(body, ";", |stat| stat write(w))
    }

}

CStatement: abstract class {
    
    write: abstract func (oc: OcWriter)
    
}

nop := CNop new()

CNop: class extends CStatement {
    
    write: func (oc: OcWriter) {}
    
}

CBlock: class extends CStatement {
    body := ArrayList<CStatement> new()
    
    init: func {}
    
    write: func (w: OcWriter) {
        w writeBlock(body, ";", |stat| stat write(w))
    }
}

CReturn: class extends CStatement {
    expr: CExpr
    
    init: func (=expr) {}
    
    write: func (w: OcWriter) {
        w app("return")
        if(expr) {
            w app(" ")
            expr write(w)
        }
    }
}

CExpr: abstract class extends CStatement {

}


var: func (type: CType, name: String) -> CVariable { CVariable new(type, name) }

CVariable: class extends CExpr {

    type: CType
    name: String
    expr: CExpr = null

    init: func(=type, =name) {}

    write: func (w: OcWriter) {
        type write(w)
        w app(" "). app(name)
        if(expr) {
            w app(" = ")
            expr write(w)
        }
    }

}


assign: func (left, right: CExpr) -> CAssign { CAssign new(left, right) }

CAssign: class extends CExpr {

    left, right: CExpr

    init: func(=left, =right) {}

    write: func (w: OcWriter) {
	left write(w)
	w app(" = ")
	right write(w)
    }

}

acc: func ~noExpr (name: String) -> CAccess { CAccess new(null, name) }
acc:      func (expr: CExpr, name: String) -> CAccess { CAccess new(expr, name) }
accArrow: func (expr: CExpr, name: String) -> CAccess { CAccess new(deref(expr), name) }

CAccess: class extends CExpr {
    
    expr: CExpr
    name: String
    
    init: func (=expr, =name) {}
    
    write: func (w: OcWriter) {
	if(expr) match expr {
	    case d: CDeref =>
		d expr write(w)
		w app("->")
	    case =>
		expr write(w)
		w app(".")
	}
        w app(name)
    }

}

deref: func (expr: CExpr) -> CDeref { CDeref new(expr) }

CDeref: class extends CExpr {
    
    expr: CExpr
    init: func (=expr) {}
    
    write: func (w: OcWriter) {
        match expr {
            case addr: CAddressOf =>
                addr expr write(w)
            case =>
                w app("(*")
                expr write(w)
                w app(")")
        }
    }
    
}

addrOf: func (expr: CExpr) -> CAddressOf { CAddressOf new(expr) }

CAddressOf: class extends CExpr {
    
    expr: CExpr
    init: func (=expr) {}
    
    write: func (w: OcWriter) {
        match expr {
            case addr: CAddressOf =>
                addr expr write(w)
            case =>
                w app("&(")
                expr write(w)
                w app(")")
        }
    }
    
}

call: func (name: String, args: ...) -> CCall {
    c := CCall new(name)
    args each(|arg|
	match arg {
	    case expr: CExpr =>
		c args add(expr)
	    case s: String => // strings are string literals
		c args add(str(s))
	    case n: SSizeT => // numbers are literals by default
		c args add(int(n as Int64))
	}
    )
    c
}

CCall: class extends CExpr {
    
    name: String
    args := ArrayList<CExpr> new()
    
    init: func(=name) {}
    
    write: func (w: OcWriter) {
        w app(name)
        w writeEach(args, "(", ", ", ")", |arg| arg write(w))
    }
    
}

int: func (val: Int64) -> CIntLiteral { CIntLiteral new(val) }

CIntLiteral: class extends CExpr {
    val: Int64

    init: func(=val) {}

    write: func (w: OcWriter) {
	w app("%Ld" format(val))
    }

}

str: func (val: String) -> CStringLiteral { CStringLiteral new(val) }

CStringLiteral: class extends CExpr {
    val: String
    
    init: func(=val) {}
    
    write: func (w: OcWriter) {
        w app('"'). app(EscapeSequence escape(val)). app('"')
    }
}

CTypeDecl: abstract class {

    write: abstract func (w: OcWriter)

    getType: abstract func -> CType
    type: CType { get { getType() } }

}

CStructDecl: class extends CTypeDecl {

    name: String
    elements := ArrayList<CVariable> new()

    type: CType

    init: func(=name) {
	type = CBaseType new("struct " + name)
    }

    write: func (w: OcWriter) {
        w nl(). nl(). app("struct "). app(name)
        w writeBlock(elements, ";", |stat| stat write(w))
	w app(';')
    }

    getType: func -> CType { type }

}

CType: abstract class extends CExpr {
    write: abstract func (w: OcWriter) {}

    pointer: func -> CPointerType {
	CPointerType new(this)
    }
}

type: func (name: String) -> CBaseType { CBaseType new(name) }

CBaseType: class extends CType {

    name: String
    init: func(=name) {}

    write: func (w: OcWriter) {
        w app(name)
    }

}

CPointerType: class extends CType {

    inner: CType
    init: func(=inner) {}

    write: func (w: OcWriter) {
	inner write(w)
	w app('*')
    }

}


