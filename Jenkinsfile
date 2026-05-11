pipeline {
  agent any

  environment {
    ANSIBLE_IMAGE = 'lab-vbox-ansible:latest'
    WORKSPACE_DIR = '/workspace'
    HOST_DIR      = "${env.LAB_HOST_PATH}"

    // La VM la gestiona Vagrant en el host. Desde el contenedor Jenkins
    // se accede al host (y por tanto a los port-forwards de VirtualBox)
    // via host.docker.internal.
    VM_HOST       = 'host.docker.internal'
    VM_SSH_PORT   = '2222'
    VM_USER       = 'vagrant'
    VM_HTTP_PORT  = '8081'
    VM_PROM_PORT  = '9090'
    VM_GRAF_PORT  = '3000'

    // URLs visibles para humanos (desde el navegador del host).
    LAB_DISPLAY_HOST = 'localhost'
  }

  stages {

    stage('0. Comprobar clave SSH') {
      steps {
        sh '''
          if [ ! -f /root/.ssh/id_rsa ]; then
            echo "ERROR: /root/.ssh/id_rsa no encontrado."
            echo "Ejecuta primero: bash scripts/01-setup-virtualbox.sh"
            exit 1
          fi
          echo "SSH key OK: $(cat /root/.ssh/id_rsa.pub)"
        '''
      }
    }

    stage('1. Build: imagen Ansible') {
      steps {
        sh '''
          docker build -f ${WORKSPACE_DIR}/docker/Dockerfile.ansible \
            -t ${ANSIBLE_IMAGE} ${WORKSPACE_DIR}
        '''
      }
    }

    stage('2. Esperar SSH de la VM') {
      steps {
        sh '''
          echo "Esperando SSH en ${VM_HOST}:${VM_SSH_PORT} ..."
          timeout 180 bash -c \
            "until bash -c 'echo > /dev/tcp/${VM_HOST}/${VM_SSH_PORT}' 2>/dev/null; do
               sleep 5; echo 'aun no disponible...';
             done"
          echo "SSH listo."
        '''
      }
    }

    stage('3. Generar inventario Ansible') {
      steps {
        writeFile file: "${env.WORKSPACE_DIR}/ansible/inventory.ini", text: """\
[web]
${env.VM_HOST} ansible_user=${env.VM_USER} ansible_port=${env.VM_SSH_PORT} ansible_ssh_private_key_file=/root/.ssh/id_rsa ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'

[web:vars]
lab_display_host=${env.LAB_DISPLAY_HOST}
lab_apache_port=${env.VM_HTTP_PORT}
lab_prom_port=${env.VM_PROM_PORT}
lab_graf_port=${env.VM_GRAF_PORT}
"""
      }
    }

    stage('4. Ansible Deploy') {
      steps {
        sh '''
          docker run --rm \
            --add-host=host.docker.internal:host-gateway \
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

    stage('5. Verificacion') {
      steps {
        sh '''
          echo "=== Verificando servicios via ${VM_HOST} ==="
          curl -f --retry 5 --retry-delay 3 http://${VM_HOST}:${VM_HTTP_PORT}
          echo "OK Apache"
          curl -f --retry 5 --retry-delay 3 http://${VM_HOST}:${VM_PROM_PORT}/-/healthy
          echo "OK Prometheus"
          curl -f --retry 5 --retry-delay 3 http://${VM_HOST}:${VM_GRAF_PORT}/api/health
          echo "OK Grafana"
        '''
      }
    }
  }

  post {
    success {
      echo """
        ╔══════════════════════════════════════════════════╗
        ║  Infraestructura desplegada correctamente         ║
        ╠══════════════════════════════════════════════════╣
        ║  Apache:     http://${LAB_DISPLAY_HOST}:${VM_HTTP_PORT}
        ║  Prometheus: http://${LAB_DISPLAY_HOST}:${VM_PROM_PORT}
        ║  Grafana:    http://${LAB_DISPLAY_HOST}:${VM_GRAF_PORT}  (admin/admin)
        ╚══════════════════════════════════════════════════╝
      """
    }
    failure {
      echo "Pipeline fallida. Para reiniciar la VM: 'vagrant reload' en el host."
    }
  }
}
