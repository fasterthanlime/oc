
// sdk
import io/Writer
import structs/[List, HashMap]

OWriter: class {

    stream: Writer
    tabLevel := 0
    tabWidth := 2

    init: func (=stream) { }

    close: func {
        app('\n')
        stream close()
    }

    app: func ~chr (c: Char) {
        stream write(c)
    }

    app: func ~str (s: String) {
        stream write(s)
    }

    /**
     * <left> elem0 <delim> elem1 <delim> elem2 <delim> elem3 <right>
     * f is passed every elem of list and is responsible of writing them
     */
    writeEach: func ~list <T> (list: List<T>, left, delim, right: String, f: Func(T)) {
        app(left)
        first := true
        list each(|e|
            if(!first) app(delim)
            f(e)
            first = false
        )
        app(right)
    }

    writeEach: func ~map <K, V> (hash: HashMap<K, V>, left, delim, right: String, f: Func (K, V)) {
        app(left)
        first := true
        hash each(|k, v|
            if(!first) app(delim)
            f(k, v)
            first = false
        )
        app(right)
    }
    
    /**
     * {
     *   elem0 <delim>
     *   elem1 <delim>
     *   elem2 <delim>
     * }
     * f is passed every elem of list and is responsible of writing them
     */
    writeBlock: func <T> (list: List<T>, delim: String, f: Func(T)) {
        openBlock()
        list each(|e|
            nl()
            f(e)
            app(delim)
        )
        closeBlock()
    }

    writeTabs: func {
        stream write(" " times (tabLevel * tabWidth), tabLevel * tabWidth)
    }

    newUntabbedLine: func {
        stream write('\n')
    }

    nl: func {
        newUntabbedLine()
        writeTabs()
    }

    tab: func {
        tabLevel += 1
    }

    untab: func {
        tabLevel -= 1
    }

    openBlock: func {
        this app("{"). tab()
    }

    closeBlock: func {
        this untab(). nl(). app("}")
    }

}

