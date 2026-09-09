def call() {
  archiveArtifacts artifacts: 'target/*.jar,rendered-manifest.yaml', fingerprint: true
}
