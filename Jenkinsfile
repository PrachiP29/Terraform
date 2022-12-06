pipeline {
    agent any
    
    tools {
        terraform 'Terraform-Configuration'
    }
    stages {
        stage ("checkout from GIT") {
            steps {
                git branch: 'main', credentialsId: 'git', url: 'https://github.com/PrachiP29/Terraform'
                sh 'git checkout v1.66.0'
            }
        }
        stage ("terraform ls") {
            steps {
                sh 'ls'
            }
        }
        stage ("terraform init") {
            steps {
                sh 'terraform init'
            }
        }
        
        stage ("terraform validate") {
            steps {
                sh 'terraform validate'
            }
        }
        stage ("terrafrom plan") {
            steps {
                sh 'terraform plan '
            }
        }
        stage ("terraform apply") {
            steps {
                sh 'terraform apply --auto-approve'
            }
        }
    }
}
