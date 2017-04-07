pipeline {
  agent any
  stages {
    stage('env') {
      steps {
        parallel(
          "env": {
            sh '''pwd
ls'''
            
          },
          "post2slack": {
            sh 'post2slack -m "Jenkins"'
            
          }
        )
      }
    }
  }
  environment {
    CHANNEL = '#rmanzoku-tl'
    WEBHOOK_URL = 'https://hooks.slack.com/services/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'
    PATH = '$PWD:$PATH'
  }
}