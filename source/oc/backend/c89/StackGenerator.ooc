
import structs/Stack, Ast

StackGenerator: abstract class {

    stack := Stack<CNode> new()

    push: func (o: CNode) {
        stack push(o)
    }

    peek: func <T> (T: Class) -> T {
        o := stack peek()
	    if(!o instanceOf?(T)) {
    	    Exception new("Expected " + T name + ", peek'd " + o class name)
    	}
	    o
    }

    pop: func <T> (T: Class) -> T {
    	o := stack pop()
	    if(!o instanceOf?(T)) {
    	    Exception new("Expected " + T name + ", pop'd " + o class name)
    	}
    	o
    }
    
    find: func <T> (T: Class) -> T {
        i := stack data size - 1
        while(i >= 0) {
            node := stack data get(i) as CNode
            if(node instanceOf?(T)) {
                return node
            }
            i -= 1
        }
        null
    }

}
