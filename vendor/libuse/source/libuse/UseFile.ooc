
// sdk
import structs/[ArrayList, HashMap]
import io/File

// ours
import UseFileParser

/**
 * AST for a .use file
 */
UseFile: class {

    identifier:    String { get set }
    name:          String { get set }
    description:   String { get set }
    versionNumber: String { get set }
    sourcePath:    String { get set }
    linker:        String { get set }
    main:          String { get set }
    binarypath:    String { get set }

    imports             : ArrayList<String> { get set }
    preMains            : ArrayList<String> { get set }
    androidLibs         : ArrayList<String> { get set }
    androidIncludePaths : ArrayList<String> { get set }
    oocLibPaths         : ArrayList<File> { get set }

    properties := ArrayList<UseProperties> new()

    file: File

    /**
     * Read a use file from its identifier.
     */
    init: func ~ident (=identifier) {
        init(UseFileParser findUse(identifier))
    }

    /**
     * Read a use file from a specific file
     */
    init: func ~file (=file) {
        imports             = ArrayList<String> new()
        preMains            = ArrayList<String> new()
        androidLibs         = ArrayList<String> new()
        androidIncludePaths = ArrayList<String> new()
        oocLibPaths         = ArrayList<File> new()
        UseFileParser new(this, file)
    }

}

/**
 * Represents the requirement for a .use file, ie. a dependency
 * The 'ver' string, if non-null/non-empty, should specify a minimal
 * accepted version.
 */
Requirement: class {
    name, ver: String
    useFile: UseFile { get set }

    init: func (=name, =ver)
}

/**
 * A custom package is an inline pkg-config like definition
 * that allows specifying copmiler and linker flags.
 */
CustomPkg: class {
    utilName: String
    names := ArrayList<String> new()
    cflagArgs := ArrayList<String> new()
    libsArgs := ArrayList<String> new()

    init: func (=utilName)
}

/**
 * An additional is a .c file that you want to add to your ooc project to be
 * compiled in.
 */
Additional: class {
    relative: File { get set }
    absolute: File { get set }

    init: func (=relative, =absolute)
}

/**
 * Properties in a .use file that are versionable
 */
UseProperties: class {
    useFile: UseFile
    useVersion: UseVersion { get set }

    pkgs                : ArrayList<String> { get set }
    customPkgs          : ArrayList<CustomPkg> { get set }
    additionals         : ArrayList<Additional> { get set }
    frameworks          : ArrayList<String> { get set }
    includePaths        : ArrayList<String> { get set }
    includes            : ArrayList<String> { get set }
    libPaths            : ArrayList<String> { get set }
    libs                : ArrayList<String> { get set }

    requirements        : ArrayList<Requirement> { get set }

    init: func (=useFile, =useVersion) {
        pkgs                = ArrayList<String> new()
        customPkgs          = ArrayList<CustomPkg> new()
        additionals         = ArrayList<Additional> new()
        frameworks          = ArrayList<String> new()
        includePaths        = ArrayList<String> new()
        includes            = ArrayList<String> new()
        libPaths            = ArrayList<String> new()
        libs                = ArrayList<String> new()

        requirements        = ArrayList<Requirement> new()
    }

    merge!: func (other: This) -> This {
        pkgs                      addAll(other pkgs)
        customPkgs                addAll(other customPkgs)
        additionals               addAll(other additionals)
        frameworks                addAll(other frameworks)
        includePaths              addAll(other includePaths)
        includes                  addAll(other includes)
        libPaths                  addAll(other libPaths)
        libs                      addAll(other libs)
    }
}

/**
 * Versioned block in a use def file
 *
 * This one is always satisfied
 */
UseVersion: class {
    useFile: UseFile

    init: func (=useFile)

    satisfied?: func (target: Target) -> Bool {
        true
    }

    toString: func -> String {
        "true"
    }

    _: String { get { toString() } }
}

UseVersionValue: class extends UseVersion {
    value: String

    init: func (.useFile, =value) {
        super(useFile)
    }

    satisfied?: func (target: Target) -> Bool {
        match value {
            case "linux" =>
                target == Target LINUX
            case "windows" =>
                target == Target WINDOWS
            case "solaris" =>
                target == Target SOLARIS
            case "haiku" =>
                target == Target HAIKU
            case "apple" =>
                target == Target OSX
            case "freebsd" =>
                target == Target FREEBSD
            case "openbsd" =>
                target == Target OPENBSD
            case "netbsd" =>
                target == Target NETBSD
            case "dragonfly" =>
                target == Target DRAGONFLY
            case "android" =>
                // android version not supported yet, false by default
                false
            case "ios" =>
                // ios version not supported yet, false by default
                false
            case =>
                message := "Unknown version #{value}"
                raise(UseFormatError new(useFile, message) toString())
                false
        }
    }

    toString: func -> String {
        "%s" format(value)
    }
}

UseVersionAnd: class extends UseVersion {
    lhs, rhs: UseVersion

    init: func (.useFile, =lhs, =rhs) {
        super(useFile)
    }

    satisfied?: func (target: Target) -> Bool {
        lhs satisfied?(target) && rhs satisfied?(target)
    }

    toString: func -> String {
        "(%s && %s)" format(lhs _, rhs _)
    }
}

UseVersionOr: class extends UseVersion {
    lhs, rhs: UseVersion

    init: func (.useFile, =lhs, =rhs) {
        super(useFile)
    }

    satisfied?: func (target: Target) -> Bool {
        lhs satisfied?(target) || rhs satisfied?(target)
    }

    toString: func -> String {
        "(%s || %s)" format(lhs _, rhs _)
    }
}

UseVersionNot: class extends UseVersion {
    inner: UseVersion

    init: func (.useFile, =inner) {
        super(useFile)
    }

    satisfied?: func (target: Target) -> Bool {
        !inner satisfied?(target)
    }

    toString: func -> String {
        "!(%s)" format(inner _)
    }
}

/**
 * Compilation target
 */
Target: enum {
    LINUX
    WINDOWS
    SOLARIS
    HAIKU
    OSX
    FREEBSD
    OPENBSD
    NETBSD
    DRAGONFLY
}

/**
 * Syntax or other error in .use file
 */
UseFormatError: class {
    useFile: UseFile
    message: String

    init: func (=useFile, =message)

    toString: func -> String {
        "Error while parsing #{useFile file path}: #{message}"
    }
}

