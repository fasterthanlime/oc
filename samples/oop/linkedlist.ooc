

// : vs :=

addConverter("ClassDecl", |comp, _class|
    _cover: comp createNode("CoverDecl")
    _metaclass: comp createNode("CoverDecl")
    _cover fields add("class", _metaclass)
    _cover fields each(|field|
	field static? ifTrue(
	    _cover, _metaclass
	) add(field)
    )
    _cover
)

// ------------------------------------------

ServerSocket: class {
    accept: static func (port: Int) -> Socket { /* ... */ }
}

Socket: class {
    close: func { /* ... */ }
}

// ------------------------------------------

ServerSocket: cover {
    accept: func (port: Int) -> Socket { /* ... */ }
}

Socket: cover {
    class: cover {
	close: func { /* ... */ }
    }
}
