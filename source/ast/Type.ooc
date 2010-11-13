

import Node
import middle/Resolver

Type: abstract class extends Node {

    

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
