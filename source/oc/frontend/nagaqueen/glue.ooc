
import oc/Plugins
import oc/frontend/nagaqueen/Frontend

// let's register ourselves with oc
Plugins registerFrontend("nagaqueen", nagaqueen_FrontendFactory new())

