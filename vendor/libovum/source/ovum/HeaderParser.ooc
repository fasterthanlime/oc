
import io/[File, FileReader], os/[Time, Env], structs/HashMap

PreprocessorReader: class extends FileReader {

    init: func (path: String) {
        super(path)
    }

    read: func ~char -> Char {
        c := super()
        match c {
            case '\\' =>
                if(super() == '\n')
                    return super() // ignore both, it's a line continuation
                else
                    rewind(1) // whoops, nevermind, I wasn't there
        }
        c
    }

}

Header: class {

    debug := false
    path: String
    fR: FileReader
    symbols := HashMap<String, String> new()

    find: static func (name: String) -> Header {
        file := File new("/usr/local/include", name)
        if(file exists?()) return new(file path)

        file = File new("/usr/include", name)
        if(file exists?()) return new(file path)

        // TODO: what about local includes?
        cInc := Env get("C_INCLUDE_PATH") 
        if(cInc) {
            file = File new(cInc, name)
            if(file exists?()) return new(file path)
        }

        "Include <%s> not found!" printfln(name)
        null
    }

    init: func (=path) {
        fR = PreprocessorReader new(path)
        parse()
    }

    parse: func {
        "Parsing #{path}" println()
        lastId: String

        while(fR hasNext?()) {
            skipComments()
            if(!fR hasNext?()) return

            mark := fR mark()
            match (c1 := fR read()) {
                case '#' =>
                    skipWhitespace()
                    dir := fR readWhile(|c| !c whitespace?())
                    log("Skipping directive #{dir}")
                    skipLine()
                case '(' =>
                    parenCount := 1
                    call := fR readWhile(|c|
                        match c {
                            case '(' => parenCount += 1; true
                            case ')' => parenCount -= 1; true
                            case     => parenCount > 0
                        }
                    ) replaceAll("\n", "") trimRight(")")
                    log("Got symbol #{lastId}(#{call})")
                    symbols put(lastId, call)
                case '{' =>
                    braceCount := 1
                    fR readWhile(|c|
                        match c {
                            case '{' => braceCount += 1; true
                            case '}' => braceCount -= 1; true
                            case     => braceCount > 0
                        }
                    )
                    log("Skipped braces to #{fR mark()}")
                case '[' =>
                    braceCount := 1
                    fR readWhile(|c|
                        match c {
                            case '[' => braceCount += 1; true
                            case ']' => braceCount -= 1; true
                            case     => braceCount > 0
                        }
                    )
                    log("Skipped square braces to #{fR mark()}")
                case ';' =>
                    log("End of line, should probably handle stuff, just skipping for now!")
                case '*' =>
                    log("Pointer type, maybe? got *")
                case =>
                    fR rewind(1)

                    id := readIdentifier()
                    if(id) {
                        lastId = id
                        match id {
                            case "struct" =>
                                skipWhitespace()
                                id2 := readIdentifier()
                                if(!id2) {
                                    log("Aborting on unfinished struct")
                                    return
                                }
                                log("Got type 'struct #{id2}'")
                            case =>
                                log("Got '#{id}'")
                        }
                    } else if(c1 whitespace?()) {
                        // skip
                        log("Skipping whitespace")
                        fR read(). read()
                    } else {
                        log("Aborting on unknown char '%c' (code %d)" format(c1, c1 as Int))
                        return
                    }
            }
        }

        "Read #{symbols size} symbols: " println()
        symbols each(|name, val|
            "'#{name}' => '#{val}'" println()
        )
    }

    readIdentifier: func -> String {
        mark := fR mark()
        c := fR read()

        match {
            case c alpha?() || c == '_' =>
                "%c%s" format(c, fR readWhile(|c| c alphaNumeric?() || c == '_'))
            case =>
                fR reset(mark)
                null
        }
    }

    skipLine: func {
        fR readWhile(|c| c != '\n')
    }

    skipWhitespace: func {
        fR readWhile(|c| c whitespace?())
    }

    skipComments: func {
        while(true) {
            skipWhitespace()

            mark := fR mark()
            match (c1 := fR read()) {
                case '/' => match(c2 := fR read()) {
                    case '/' => skipLine()
                    //"[%d] skipped single-line comment!" printfln(mark); 
                    continue
                    case '*' => fR skipUntil("*/"). rewind(1)
                    //"[%d] skipped multi-line comment!"  printfln(mark);
                    continue
                }
                case =>
                    //"At %d, stumbled upon %c" printfln(mark, c1)
            }

            fR reset(mark)
            break
        }
    }

    log: final func (message: String) {
        if (debug) {
            "[#{fR mark()}] #{message}" println()
        }
    }

}

