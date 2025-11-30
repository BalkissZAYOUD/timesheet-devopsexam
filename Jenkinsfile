pipeline {
    agent any

    environment {
        SONARQUBE_TOKEN = credentials('sonarqube')

        SLACK_WEBHOOK_URL = credentials('slack-webhook')


    }

    stages {

        /* --------------------- 1) CHECKOUT --------------------- */
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/BalkissZAYOUD/timesheet-devopsexam.git'
            }
        }

        /* --------------------- 2) BUILD MAVEN --------------------- */
        stage('Build Maven') {
            steps {
                sh 'mvn clean install'
            }
        }

        /* --------------------- 3) SAST : DEPENDENCY CHECK --------------------- */
        stage('OWASP Dependency Check') {
            steps {
                sh 'mkdir -p dependency-check-report'
                dependencyCheck additionalArguments: '''
                    --scan .
                    --format HTML
                    --format XML
                    --out dependency-check-report
                ''',
                odcInstallation: 'dependency-check'
            }
        }

        stage('Publish Dependency Check Report') {
            steps {
                dependencyCheckPublisher pattern: 'dependency-check-report/dependency-check-report.xml'
            }
        }

        /* --------------------- 4) DAST : OWASP ZAP --------------------- */
        stage('OWASP ZAP Scan') {
            steps {
                script {
                    sh '''
                        mkdir -p zap-report
                        docker run --rm \
                            -v $(pwd)/zap-report:/zap/wrk \
                            owasp/zap2docker-stable zap-baseline.py \
                            -t http://localhost:8080 \
                            -r zap-report.html || true
                    '''
                }
                archiveArtifacts artifacts: 'zap-report/zap-report.html', allowEmptyArchive: true
            }
        }

        /* --------------------- 5) TRIVY SCAN --------------------- */
        stage('Trivy Scan') {
            steps {
                script {
                    sh '''
                        mkdir -p trivy-report
                        trivy clean --java-db || true
                        trivy fs --format json --output trivy-report/trivy-report.json \
                              --exit-code 1 --severity CRITICAL,HIGH \
                              . || true
                    '''
                }
                archiveArtifacts artifacts: 'trivy-report/trivy-report.json', allowEmptyArchive: true
            }
        }

        /* --------------------- 6) SONARQUBE ANALYSIS --------------------- */
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarServer') {
                    sh 'mvn sonar:sonar -Dsonar.login=$SONARQUBE_TOKEN'
                }
            }
        }

        /* ---------------------minikube--------------------- */
       stage('Set Minikube Docker Env') {
           steps {
               script {
                   sh 'eval $(minikube -p minikube docker-env)'
               }
           }
       }
       /* ---------------------------Docker-----------------------*/
       stage('Docker Build & Local Test') {
           steps {
               script {
                   sh '''
                       docker build -t timesheet-devops:latest .
                       docker run --rm -d --name test-app -p 8080:8080 timesheet-devops:latest
                       sleep 10
                       docker logs test-app
                       docker stop test-app
                   '''
               }
           }
       }

        /* --------------------- 8) PUSH DOCKER HUB --------------------- */
        stage('Docker Push to Hub') {
            steps {
                script {
                    withDockerRegistry([credentialsId: 'dockerhub', url: '']) {
                        sh 'docker push balkiszayoud/timesheet-devops:latest'
                    }
                }
            }
        }

        /* --------------------- 9) DEPLOYMENT KUBERNETES --------------------- */
         stage('Deploy to Kubernetes') {
          steps {
              script {
                  sh 'kubectl set image deployment/timesheet-deployment timesheet=timesheet-devops:latest'
                  sh 'kubectl rollout status deployment/timesheet-deployment'
              }
            }
          }

    /* --------------------- NOTIFICATIONS SLACK --------------------- */
    post {
        success {

            echo "Pipeline terminé avec succès !"

            /* 🔔 MESSAGE SLACK */
            sh """
                curl -X POST -H "Content-type: application/json" \
                --data '{"text":"✅ Pipeline terminé avec succès ! Job: ${JOB_NAME} Build: #${BUILD_NUMBER}"}' \
                $SLACK_WEBHOOK_URL
            """

            /* 📎 ENVOI DES RAPPORTS */
            sh """
                # Dependency Check
                curl -F file=@dependency-check-report/dependency-check-report.html \
                     -F "initial_comment=📄 Rapport Dependency Check" \
                     -F channels=security \
                     -H "Authorization: Bearer $SLACK_TOKEN" \
                     https://slack.com/api/files.upload

                # OWASP ZAP
                curl -F file=@zap-report/zap-report.html \
                     -F "initial_comment=🕷️ Rapport OWASP ZAP" \
                     -F channels=security \
                     -H "Authorization: Bearer $SLACK_TOKEN" \
                     https://slack.com/api/files.upload

                # Trivy
                curl -F file=@trivy-report/trivy-report.json \
                     -F "initial_comment=🔍 Rapport Trivy Scan" \
                     -F channels=security \
                     -H "Authorization: Bearer $SLACK_TOKEN" \
                     https://slack.com/api/files.upload
            """
        }

        failure {

            echo "Le pipeline a échoué !"

            /* 🔔 MESSAGE SLACK ÉCHEC */
            sh """
                curl -X POST -H "Content-type: application/json" \
                --data '{"text":"❌ Le pipeline a échoué ! Job: ${JOB_NAME} Build: #${BUILD_NUMBER}"}' \
                $SLACK_WEBHOOK_URL
            """

            /* 📎 RAPPORTS MÊME EN CAS D'ÉCHEC */
            sh """
                curl -F file=@dependency-check-report/dependency-check-report.html \
                     -F "initial_comment=📄 Rapport Dependency Check (échec)" \
                     -F channels=security \
                     -H "Authorization: Bearer $SLACK_TOKEN" \
                     https://slack.com/api/files.upload

                curl -F file=@zap-report/zap-report.html \
                     -F "initial_comment=🕷️ Rapport OWASP ZAP (échec)" \
                     -F channels=security \
                     -H "Authorization: Bearer $SLACK_TOKEN" \
                     https://slack.com/api/files.upload

                curl -F file=@trivy-report/trivy-report.json \
                     -F "initial_comment=🔍 Rapport Trivy (échec)" \
                     -F channels=security \
                     -H "Authorization: Bearer $SLACK_TOKEN" \
                     https://slack.com/api/files.upload
            """
        }
    }
}

}