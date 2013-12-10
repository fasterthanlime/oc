
// sdk
import structs/[ArrayList]

// ours
import oc/ast/Node

/**
 * Fast array-backed list structure for AST nodes
 */
NList: class extends ArrayList<Node> {

    init: func {
        super()
    }

    fastget: final inline func (index: Int) -> Node {
        (data as Node*)[index]
    }

}

