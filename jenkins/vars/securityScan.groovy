def call() {
  sh 'trivy fs --exit-code 1 --ignore-unfixed --severity CRITICAL,HIGH .'
}
