def call(String imageName, String tag = env.GIT_COMMIT) {
  sh "docker build --pull -t ${imageName}:${tag} ."
  echo "Push is intentionally environment-specific. Configure Jenkins credentials and uncomment docker push for a real registry."
}
