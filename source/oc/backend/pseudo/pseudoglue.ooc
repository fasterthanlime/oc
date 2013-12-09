
import oc/Plugins
import oc/backend/pseudo/PseudoBackend

// let's register ourselves with oc
Plugins registerBackend("pseudo", pseudo_Backend new())

