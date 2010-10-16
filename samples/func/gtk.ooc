
Window ("Hi GTK world") .with <- [
    Button ("Click me!", -> "You tricked me :(" println())
    Button ("Exit",      -> exit())
    TabbedPad <- [
        Tab ("About") .with <- [
            Label ("This is a simple GTK example show-casing proposed ooc syntax")
        ]
        Tab ("Nuclear warfare") .with <- [
            Label ("What do you want to do today, Mr. President?")
            Button ("Blow up the world",       -> blowUp())
            Button ("Nah, just get ice cream", -> giantFreezer())
        ]
    ]
]. showAll()

Gtk mainLoop()


Widget: abstract class {

    _widget: null

    connect: c -> gtk_signal_connect(_widget, )

}

Container: abstract class extends Container {

    add: w -> gtk_container_add(w widget

    with: widgets -> {
        widgets each <- add
    }

}


Window: class extends Container {

    call: title -> new() .{
        _widget = gtk_window_new(title)
    }
    
}

Button: class extends Container {

    setLabel: ->         gtk_button_set_label(_widget, $1)
    getLabel: -> String  gtk_button_get_label(_widget)

    call: (caption, clicked) -> new() .{
        _widget = gtk_button_new()
        setLabel(caption)
        connect("clicked", clicked)
    }
 
}



