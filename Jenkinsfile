pipeline {
  agent any

  environment {
    TF_IMAGE      = 'lab-lxd-terraform:latest'
    ANSIBLE_IMAGE = 'lab-lxd-ansible:latest'
    // Path dentro del contenedor Jenkins (para docker build y writeFile)
    WORKSPACE_DIR = '/workspace'
    // Path real en el host (para volúmenes en docker run)
    HOST_DIR      = "${env.LAB_HOST_PATH}"
    LXD_SOCKET    = '/var/snap/lxd/common/lxd/unix.socket'
  }

  stages {

    stage('1. Build: Imágenes Docker') {
      steps {
        sh '''
          docker build -f ${WORKSPACE_DIR}/docker/Dockerfile.terraform \
            -t ${TF_IMAGE} ${WORKSPACE_DIR}
          docker build -f ${WORKSPACE_DIR}/docker/Dockerfile.ansible \
            -t ${ANSIBLE_IMAGE} ${WORKSPACE_DIR}
        '''
      }
    }

    stage('2. Terraform Init') {
      steps {
        sh '''
          SSH_KEY=$(cat /root/.ssh/id_rsa.pub 2>/dev/null) || { echo "ERROR: SSH key not found. Rebuild Jenkins with: docker compose up -d --build"; exit 1; }
          docker run --rm \
            -v ${LXD_SOCKET}:${LXD_SOCKET} \
            -v ${HOST_DIR}/terraform:/terraform \
            -w /terraform \
            -e TF_VAR_ssh_public_key="${SSH_KEY}" \
            ${TF_IMAGE} init
        '''
      }
    }

    stage('3. Terraform Apply') {
      steps {
        sh '''
          SSH_KEY=$(cat /root/.ssh/id_rsa.pub 2>/dev/null) || { echo "ERROR: SSH key not found. Rebuild Jenkins with: docker compose up -d --build"; exit 1; }
          docker run --rm \
            -v ${LXD_SOCKET}:${LXD_SOCKET} \
            -v ${HOST_DIR}/terraform:/terraform \
            -w /terraform \
            -e TF_VAR_ssh_public_key="${SSH_KEY}" \
            ${TF_IMAGE} apply -auto-approve
        '''
      }
    }

    stage('4. Obtener IP de la VM') {
      steps {
        script {
          def vmIp = sh(
            script: '''
              SSH_KEY=$(cat /root/.ssh/id_rsa.pub 2>/dev/null) || { echo "ERROR: SSH key not found."; exit 1; }
              docker run --rm \
                -v ${LXD_SOCKET}:${LXD_SOCKET} \
                -v ${HOST_DIR}/terraform:/terraform \
                -w /terraform \
                -e TF_VAR_ssh_public_key="${SSH_KEY}" \
                ${TF_IMAGE} output -raw vm_ip
            ''',
            returnStdout: true
          ).trim()

          env.VM_IP = vmIp
          echo "VM IP: ${vmIp}"

          writeFile file: "${env.WORKSPACE_DIR}/ansible/inventory.ini", text: """\
[web]
${vmIp} ansible_user=ubuntu ansible_ssh_private_key_file=/root/.ssh/id_rsa ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
"""
        }
      }
    }

    stage('5. Esperar SSH') {
      steps {
        sh '''
          echo "Esperando SSH en ${VM_IP}:22..."
          timeout 120 bash -c \
            "until bash -c 'echo > /dev/tcp/${VM_IP}/22' 2>/dev/null; do sleep 5; echo 'aún no disponible...'; done"
          echo "SSH listo en ${VM_IP}"
        '''
      }
    }

    stage('6. Ansible Deploy') {
      steps {
        sh '''
          docker run --rm \
            --network host \
            -v ${HOST_DIR}/ansible:/ansible \
            -v ${HOST_DIR}/ssh:/root/.ssh:ro \
            -w /ansible \
            -e ANSIBLE_CONFIG=/ansible/ansible.cfg \
            ${ANSIBLE_IMAGE} \
              -i /ansible/inventory.ini \
              /ansible/playbook.yml
        '''
      }
    }

    stage('7. Verificación') {
      steps {
        sh '''
          echo "=== Verificando servicios en ${VM_IP} ==="
          curl -f --retry 5 --retry-delay 3 http://${VM_IP}
          echo "✓ Apache OK"
          curl -f --retry 5 --retry-delay 3 http://${VM_IP}:9090/-/healthy
          echo "✓ Prometheus OK"
          curl -f --retry 5 --retry-delay 3 http://${VM_IP}:3000/api/health
          echo "✓ Grafana OK"
        '''
      }
    }
  }

  post {
    success {
      echo """
        ╔══════════════════════════════════════════════╗
        ║  Infraestructura desplegada correctamente     ║
        ╠══════════════════════════════════════════════╣
        ║  Apache:     http://${VM_IP}                 ║
        ║  Prometheus: http://${VM_IP}:9090            ║
        ║  Grafana:    http://${VM_IP}:3000  (admin)   ║
        ╚══════════════════════════════════════════════╝
      """
    }
    failure {
      sh '''
        docker run --rm \
          -v ${LXD_SOCKET}:${LXD_SOCKET} \
          -v ${HOST_DIR}/terraform:/terraform \
          -w /terraform \
          -e TF_VAR_ssh_public_key="$(cat /root/.ssh/id_rsa.pub 2>/dev/null)" \
          ${TF_IMAGE} destroy -auto-approve || true
      '''
    }
  }
}
