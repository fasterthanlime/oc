
import oc/Plugins
import oc/frontend/nagaqueen/NQFrontend

// let's register ourselves with oc
Plugins registerFrontend("nagaqueen", nagaqueen_FrontendFactory new())

