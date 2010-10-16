
import ast/[Module, Node, FuncDecl, Access, Var, Scope, Type,
    Call, StringLit]

import structs/[HashMap, List], io/[File, FileWriter]

CallBack: class {
    f: Func (Node)

    init: func (=f) {}
}

Backend: class {

    module: Module
    fw: FileWriter
    
    map := HashMap<Class, CallBack> new()

    init: func (=module) {
        file := File new("oc_tmp", (module fullName replaceAll('/', File separator)) + ".c")
        file parent() mkdirs()
        fw = FileWriter new(file)
        
        put(Call, func(c: Call) {
            write(c subject)
            fw write("(")
            writeCommaSeparated(c args)
            fw write(")")
        })

        put(StringLit, func(c: StringLit) {
            fw write('"'). write(c value). write('"')
        })

        put(Scope, func(s: Scope) {
            fw write("{\n")
            s body each(|stat|
                write(stat)
                fw write(";\n")
            )
            fw write("}\n")
        })

        put(Var, func (v: Var) {
            write(v type)
            fw write(" "). write(v name)
            if(v expr) {
                fw write(" = ")
                write(v expr)
            }
        })
        
        put(BaseType, func (b: BaseType) {
            fw write(b name)
        })

        put(Access, func (a: Access) {
            fw write(a name)
        })
    }

    put: func (c: Class, f: Func (Node)) {
        map put(c, CallBack new(f))
    }

    writeCommaSeparated: func (l: List<Node>) {
        first := true
        l each(|n|
            if(!first) fw write(", ")
            write(n)
            first = false
        )
    }

    write: func (n: Node) {
        cb := map get(n class)
        if(cb) {
            cb f(n)
        } else {
            ("Unknown node type " + n class name) printfln()
        }
    }

    generate: func {
        write(module body)
    }

}



