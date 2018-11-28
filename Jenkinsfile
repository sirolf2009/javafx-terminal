pipeline {
  agent any
  stages {
    stage('Compile') {
      steps {
        sh '''Xvfb :99 &>/dev/null &
export DISPLAY=:99
export GPG_TTY=$(tty)
mvn clean deploy -P release'''
      }
    }
  }
}
