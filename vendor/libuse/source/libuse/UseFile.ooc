
// sdk
import io/[File, FileReader]

/**
 * AST for a .use file
 */
UseFile: class {

    file: File

    init: func (=file) {
        "Reading use file #{file}" println()

        fR := FileReader new(file)
        while (fR hasNext?()) {
            line := fR readLine()
            "line: #{line}" println()
        }
    }

}
