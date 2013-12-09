
import oc/Plugins
import oc/backend/c89/Backend

// let's register ourselves with oc
Plugins registerBackend("c89", c89_Backend new())

