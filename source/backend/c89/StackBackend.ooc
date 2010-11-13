
import structs/Stack

StackBackend: class {

    stack := Stack<Object> new()

    push: func (o: Object) {
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

}
