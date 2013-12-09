
// branches
import oc/ast/[Node, Expression, Statement]

// leafs
import oc/ast/[Access, Call, CoverDecl, FuncDecl, NumberLit,
       Return, Scope, StringLit, Type, Var]

Inquisitor: abstract class {

    visitNode: func (node: Node) {
        if (!node) return
        node surrender(this)
    }

    visitCoverDecl: func (cd: CoverDecl)
    visitFuncDecl: func (e: FuncDecl)
    visitVar: func (v: Var)

    visitScope: func (s: Scope)

    visitAccess: func (a: Access)
    visitCall: func (c: Call)
    visitReturn: func (r: Return)

    visitNumberLit: func (nl: NumberLit)
    visitStringLit: func (sl: StringLit)

}

