
// sdk
import io/[File, FileWriter], structs/[List, ArrayList]
import text/EscapeSequence

// ours
import ovum/OWriter

/**
 * Base class for any C node
 */
CNode: abstract class {

    seed := static 0

    /**
     * Generate a unique name that contains 'base'.
     *
     * Subclasses should override this to provide better/shorter names
     * that are still unique.
     */
    genName: func (base: String) -> String {
        seed += 1
        "__%s_%d" format(base, seed)
    }

}

/**
 * A source is a combination of .c/.h file
 */
CSource: class extends CNode {

    name: String

    includes := ArrayList<String> new()

    functions := ArrayList<CFunction> new()
    types := ArrayList<CTypeDecl> new()

    init: func (=name)

    write: func (basePath: String) {
        baseFile := File new(basePath, name) parent
        if(!baseFile exists?()) baseFile mkdirs()

        hw := OWriter new(FileWriter new(File new(basePath, name + ".h")))

        define := "__" + name map(|c| c alphaNumeric?() ? c toUpper() : '_') + "__define__"
        hw nl(). app("#ifndef "). app(define)
        hw nl(). app("#define "). app(define)

        writeClosureType(hw)

        includes each(|i| hw nl(). app("#include "). app(i))

        // FIXME: ugly hack, hardcode Bool for now.
        hw nl(). app("#ifndef Bool"). nl(). app("#define Bool int"). nl(). app("#endif")

        types each(|t| t write(hw))

        functions each(|f|
            hw nl()
            f writePrototype(hw)
            hw app(';')
        )

        cw := OWriter new(FileWriter new(File new(basePath, name + ".c")))
        cw nl(). app("#include \""). app(name). app(".h\"")
        cw nl(). app("#include <stdlib.h>")

        functions each(|f| f write(cw))

        hw nl(). app("#endif")
        hw close()
        cw close()
    }

    writeClosureType: func (w: OWriter) {
        w app("
struct Closure {
    int (*thunk)();
    void *context;
};
")
    }

}

CFunction: class extends CNode {

    returnType: CType
    name: String
    args := ArrayList<CVariable> new()
    body := ArrayList<CStatement> new()

    init: func (=returnType, =name) {}

    writePrototype: func (w: OWriter) {
        returnType write(w, |w|
            w app(' '). app(name)
            w writeEach(args, "(", ", ", ")", |arg| arg write(w))
        )
    }

    write: func (w: OWriter) {
    	w nl(). nl()
        writePrototype(w)
        w app(' ')
        w writeBlock(body, ";", |stat| stat write(w))
    }

}

CStatement: abstract class extends CNode {

    write: abstract func (oc: OWriter)

}

CBlock: class extends CStatement {
    body := ArrayList<CStatement> new()

    init: func {}

    write: func (w: OWriter) {
        w writeBlock(body, ";", |stat| stat write(w))
    }
}

CIf: class extends CBlock {
    cond: CExpr

    init: func (=cond) {}

    write: func (w: OWriter) {
        w app("if(")
        cond write(w)
        w app(") ")
        super()
    }

}

CReturn: class extends CStatement {
    expr: CExpr

    init: func (=expr) {}

    write: func (w: OWriter) {
        w app("return")
        if(expr) {
            w app(" ")
            expr write(w)
        }
    }
}

CExpr: abstract class extends CStatement {

    deref: func -> CExpr {
        CDeref new(this)
    }

    addrOf: func -> CExpr {
        CAddressOf new(this)
    }

}

nop := CNop new()

CNop: class extends CExpr {
    init: func

    write: func (oc: OWriter)
}

var: func (type: CType, name: String) -> CVariable { CVariable new(type, name) }

CVariable: class extends CExpr {

    type: CType
    name: String
    expr: CExpr = null

    shallow? : Bool { get set }

    init: func(=type, =name) {}

    write: func (w: OWriter) {
        type write(w, name)
        if(expr) {
            w app(" = ")
            expr write(w)
        }
    }

    acc: func -> CAccess {
        CAccess new(null, name)
    }

}


assign: func (left, right: CExpr) -> CAssign { CAssign new(left, right) }

CAssign: class extends CExpr {

    left, right: CExpr

    init: func(=left, =right) {}

    write: func (w: OWriter) {
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

    write: func (w: OWriter) {
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

        write: func (w: OWriter) {
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

        write: func (w: OWriter) {
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
        fat := false

        init: func(=name) {}

        write: func (w: OWriter) {
            if(fat) {
                w app(name). app(".thunk("). app(name). app(".context")
                if(args empty?())
                    w app(")")
                else
                    w writeEach(args, ", ", ", ", ")", |arg| arg write(w))
            } else {
                w app(name)
                w writeEach(args, "(", ", ", ")", |arg| arg write(w))
            }
        }

    }

    int: func (val: Int64) -> CIntLiteral { CIntLiteral new(val) }

    CIntLiteral: class extends CExpr {
        val: String

        init: func ~fromNumber (number: Int64) {
            val = "%lld" format(number)
        }

        init: func (=val)

        write: func (w: OWriter) {
            w app(val)
        }

    }

    str: func (val: String) -> CStringLiteral { CStringLiteral new(val) }

    CStringLiteral: class extends CExpr {
        val: String

        init: func(=val) {}

        write: func (w: OWriter) {
            w app('"'). app(EscapeSequence escape(val)). app('"')
        }
    }

    CTypeDecl: abstract class {

        write: abstract func (w: OWriter)

        getType: abstract func -> CType
        type: CType { get { getType() } }

    }

    CStructDecl: class extends CTypeDecl {

        name: String
        elements := ArrayList<CVariable> new()

        _type: CType

        init: func(=name) {
            _type = CBaseType new("struct " + name)
        }

        write: func (w: OWriter) {
            w nl(). nl(). app("struct "). app(name)
            w writeBlock(elements, ";", |stat| stat write(w))
            w app(';')
        }

        getType: func -> CType { _type }

    }

    CStructLiteral: class extends CExpr {

        type: CType
        elements := ArrayList<CExpr> new()

        init: func(=type) {}

        write: func (w: OWriter) {
            w app("(")
            type write(w)
            w app(") ")
            w writeEach(elements, "{", ", ", "}", |expr| expr write(w))
        }

    }

    CType: abstract class extends CExpr {

        write: abstract func ~withAnon (w: OWriter, writeMid: Func (OWriter))

        write: func ~withName (w: OWriter, varName: String) {
            write(w, |w| w app(' '). app(varName))
        }

        write: func (w: OWriter) {
            write(w, |w|)
        }

        pointer: func -> CPointerType {
            CPointerType new(this)
        }

        void?: func -> Bool {
            false
        }

    }

    type: func (name: String) -> CBaseType { CBaseType new(name) }

    CBaseType: class extends CType {

        name: String
        init: func(=name) {}

        write: func ~withAnon (w: OWriter, writeMid: Func (OWriter)) {
            w app(name)
            writeMid(w)
        }

        void?: func -> Bool {
            name == "void"
        }

    }

    CFuncType: class extends CType {

        fat := true

        argTypes := ArrayList<CType> new()
        retType: CType

        init: func (=retType) {}

        write: func ~withAnon (w: OWriter, writeMid: Func (OWriter)) {
            if(fat) {
                w app("struct Closure")
                writeMid(w)
            } else {
                retType write(w)
                w app(" (*")
                writeMid(w)
                w app(")")
                w writeEach(argTypes, "(", ", ", ")", |argType| argType write(w))
            }
        }

    }

    CPointerType: class extends CType {

        inner: CType
        init: func(=inner) {}

        write: func ~withAnon (w: OWriter, writeMid: Func (OWriter)) {
            inner write(w)
            w app('*')
            writeMid(w)
        }

    }
