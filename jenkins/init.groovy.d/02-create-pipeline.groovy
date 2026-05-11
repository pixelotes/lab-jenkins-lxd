import jenkins.model.*
import org.jenkinsci.plugins.workflow.job.WorkflowJob
import org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition

def instance = Jenkins.getInstance()
def jobName  = "lab-devops-virtualbox"

def job = instance.getItem(jobName) ?: instance.createProject(WorkflowJob, jobName)
def jenkinsfilePath = new File('/workspace/Jenkinsfile')

if (!jenkinsfilePath.exists()) {
    println "WARN: /workspace/Jenkinsfile no encontrado, pipeline creado vacío"
    return
}

job.setDefinition(new CpsFlowDefinition(jenkinsfilePath.text, true))
job.save()
instance.save()

println "✓ Pipeline '${jobName}' sincronizado desde /workspace/Jenkinsfile"
