
import Backend

import c89/C89Backend

BackendFactory: class {
    
    make: static func (name: String) -> Backend {
        // ideally we'd use dynamic library loading here to have pluggable backends :)
        match name {
            case "c89" => C89Backend new()
            case       => "Unknown backend specified: '%s'" printfln(name); null
        }
    }
    
}
