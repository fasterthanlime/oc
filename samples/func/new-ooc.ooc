
// So, seems we're re-designing ooc.

// First things first: lose the func. Stuff like:
main: func (args: ArrayList<String>) -> Int {
}

// Will become:
main: args -> {

}

// Also, you might've noticed that.. everywhere argument types can
// be inferred, they will. Same goes for return types

add: (a, b) -> { a + b }

// unspecified types that *can't* be inferred just create macros so that both:
add("Hi ", "there")

// ...and
add(41, 1)

// ...would be legal, using two different versions of add

// Also, ':' would now mean ':=' and the old ':' would be abandoned, so:
a: 42

// and you could call functions with only one arg using <-
b: { println <- "Do stuff!" }

// Yes, {} defines a function too (no named arguments), and...
map each <- {
    "key = %s, value = %s" printfln($1, $2)
}
// .. you could refer to arguments with $n where n is the number of the arg.

// About '<-', it could also be used to pass tuples as arguments to functions, ie.
tuple: (a, b, c)
doStuff <- tuple

// Aaand when passing a function to a function, like:

map each <- (k, v) -> {...}

// then we'd rather use a little sugar instead:

map each <-> (k, v) {...}
