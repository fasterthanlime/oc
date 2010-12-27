

import Node, FuncDecl
import middle/Resolver

Type: abstract class extends Node {

    void?: func -> Bool { false }

}


BaseType: class extends Type {

    resolved := false
    name: String { get set }

    init: func (=name) {}

    resolve: func (task: Task) {
        resolved = true
    }
    
    toString: func -> String { name }

}

VoidType: class extends BaseType {
    
    init: func {
        super("void")
    }
    
    void?: func -> Bool { true }
    
}

FuncType: class extends Type {
    
    proto: FuncDecl { get set }
    
    init: func (=proto) {}
    
    // well, nothing to do
    resolve: func (task: Task) {}
    
    toString: func -> String { "Func " + proto toString() }
    
}



