# Jenkins setup

Create a Global Pipeline Library named `springboot-shared-library` pointing to the `jenkins/` directory in this repository, or copy `jenkins/vars` into your organization's shared-library repository.

The Jenkins agent must have Java 17, Maven, Docker and Helm. Install Trivy for the security stage.

For a local functional run, set Jenkins parameters `DEPLOY_DEV=false` and `DEPLOY_PROD=false`. For real deployment, set cluster access through Jenkins credentials rather than hardcoding them.
