

while : (cond, f) -> {
    if(cond(), -> 
        f()
        while(cond, f)
    )
}


3 times <- (a, b) -> {
    "Do stuff"! println()
}

3 times <-> (a, b) {
    "Do stuff!"
}



