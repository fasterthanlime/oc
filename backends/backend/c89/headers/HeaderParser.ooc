
import io/FileReader, os/Time

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

HeaderParser: class {
    
    path: String
    fR: FileReader
    
    init: func (=path) {
        fR = PreprocessorReader new(path)
    }
    
    parse: func {
        lastId: String
        
        while(fR hasNext?()) {
            skipComments()
            if(!fR hasNext?()) return
            
            mark := fR mark()
            match (c1 := fR read()) {
                case '#' =>
                    skipWhitespace()
                    //"[%d] Skipping directive #%s" printfln(mark, fR readWhile(|c| !c whitespace?()))
                    skipLine()
                case '(' =>
                    parenCount := 1
                    call := fR readWhile(|c|
                        match c {
                            case '(' => parenCount += 1; true
                            case ')' => parenCount -= 1; true
                            case     => parenCount > 0
                        }
                    ) replaceAll("\n", "")
                    "[%d] Got symbol %s(%s" printfln(mark, lastId, call)
                case ';' =>
                    //"[%d] End of line, should probably handle stuff, just skipping for now!" printfln(mark)
                case '*' =>
                    //"[%d] Pointer type, maybe? got *" printfln(mark)
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
                                    "[%d] Aborting on unfinished struct" printfln(mark)
                                    return
                                }
                                "[%d] Got type 'struct %s'" printfln(mark, id2)
                            case =>
                                //"[%d] Got '%s'" printfln(mark, id)
                        }
                    } else if(c1 whitespace?()) {
                        // skip
                        "[%d] Skipping whitespace" printfln(fR mark())
                        fR read(). read()
                    } else {
                        "[%d] Aborting on unknown char '%c', (code %d)" printfln(mark, c1, c1 as Int)
                        return
                    }
            }
        }
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
    
}


test: func {
    "Parsing done in %d ms" printfln(Time measure(||
        //hp := HeaderParser new("/usr/include/stdio.h")
        hp := HeaderParser new("/usr/include/unistd.h")
        hp parse()
    ))
}

test()
