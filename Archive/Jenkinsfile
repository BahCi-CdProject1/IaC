pipeline {
    agent any
    stages {
        stage("Clean Up"){
            steps {
                deleteDir()
            }
        }    
        stage("Pull HTML from Github Repo") {
            steps {
                sh "git clone https://github.com/BahCi-CdProject1/web.git"
            }
        }
        stage("Push file to web instance") {
            steps {
                sh "scp -r -v -o StrictHostKeyChecking=no -i /var/lib/jenkins/.ssh/test-app1.pem /var/lib/jenkins/workspace/pipeline-test1/web*/* ubuntu@172.31.57.5:/var/www/html"
            }
        }
    }
}