import jenkins.model.*
import hudson.security.*

def instance = Jenkins.getInstance()
instance.setAuthorizationStrategy(new AuthorizationStrategy.Unsecured())
instance.setSecurityRealm(new HudsonPrivateSecurityRealm(false))
instance.setCrumbIssuer(null)
instance.save()

println "✓ Seguridad y CSRF desactivados (modo lab)"
