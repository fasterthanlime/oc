
// sdk
import io/[File, FileReader]
import structs/[ArrayList, HashMap]

// ours
import UseFile

UseFileParser: class {

    cache := static HashMap<String, UseFile> new()
    libsDirs := static ArrayList<File> new()

    useFile: UseFile
    file: File

    init: func (=useFile, =file) {
        "Reading use file #{file}" println()

        fR := FileReader new(file)
        while (fR hasNext?()) {
            line := fR readLine()
            "line: #{line}" println()
        }
    }

    findUse: static func (identifier: String) -> File {
        fileName := "#{identifier}.use"

        for(dir in libsDirs) {
            if(dir path == null) continue
            res := dir findShallow(fileName, 2)
            if (res) return res
        }

        null
    }

    addLibsDir: static func (libsDir: File) {
        libsDirs add(libsDir)
    }

}

