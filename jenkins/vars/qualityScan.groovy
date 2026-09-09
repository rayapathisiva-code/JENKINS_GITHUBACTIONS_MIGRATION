def call() {
  sh 'mvn -B test'
  sh 'helm lint helm/springboot-poc'
}
