def call(String environment, String imageName, String imageTag) {
  sh "bash scripts/deploy.sh ${environment} ${imageName} ${imageTag}"
}
