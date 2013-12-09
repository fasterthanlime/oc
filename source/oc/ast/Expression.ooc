

import Statement, Type

Expression: abstract class extends Statement {

    type ::= getType()

    /** to be implemented by subclassing fuckers */
    getType: abstract func -> Type

}
