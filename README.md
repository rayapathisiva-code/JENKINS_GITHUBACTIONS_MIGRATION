# GitHub Actions – Jenkins Migration & Reusable CI/CD POC

This repository is a **working, application-backed POC** for the assessment. It uses a small Spring Boot application so the pipeline is not only YAML. The same delivery intent is represented in Jenkins and GitHub Actions.

## What this POC demonstrates

- Jenkinsfile migration to GitHub Actions
- Jenkins Shared Library replacement with a GitHub Composite Action
- Reusable Workflow consuming the Composite Action
- Java/Maven build and unit tests
- Maven dependency caching with `actions/setup-java`
- Helm lint and manifest generation
- Trivy filesystem security check
- Docker image build with immutable `GITHUB_SHA` tag
- Build artifact generation and cross-job reuse
- DEV and PROD environments
- Production approval through the GitHub `production` Environment
- Least-privilege workflow permissions
- Jenkins credentials/GitHub Secrets/OIDC design
- Enterprise migration and scaling strategy

## Repository layout

```text
.
├── src/                              # Working Spring Boot app + unit test
├── pom.xml
├── Dockerfile
├── helm/springboot-poc/              # Deployment chart
├── .github/
│   ├── actions/ci-build/action.yml   # Composite Action
│   └── workflows/
│       ├── ci.yml                    # App entry point
│       ├── reusable-ci.yml           # Reusable pipeline
│       └── deploy.yml                # DEV/PROD promotion
├── jenkins/
│   ├── Jenkinsfile
│   └── vars/                         # Shared Library functions
└── docs/architecture.md
```

## Run the application locally

Requirements: Java 17 and Maven.

```bash
mvn clean verify
mvn spring-boot:run
```

Then open `http://localhost:8080/` and `http://localhost:8080/health`.

## Build the container

```bash
mvn clean verify
docker build -t springboot-jenkins-actions-poc:local .
docker run --rm -p 8080:8080 springboot-jenkins-actions-poc:local
```

The CI image tag is `${GITHUB_SHA}` rather than `latest`. This gives traceability from deployment back to the exact source revision.

## GitHub Actions flow

`ci.yml` is intentionally small. It calls the reusable workflow:

```yaml
jobs:
  ci:
    uses: ./.github/workflows/reusable-ci.yml
    with:
      image-name: springboot-jenkins-actions-poc
```

The reusable workflow then:
1. Checks out the repository.
2. Calls the Composite Action.
3. Builds and tests with Maven and uses dependency caching.
4. Runs Helm quality checks.
5. Runs a Trivy filesystem security check.
6. Builds the Docker image with the Git SHA.
7. Generates a rendered Helm manifest.
8. Uploads the JAR and manifest as a GitHub Actions artifact.

### Why both Composite Action and Reusable Workflow?

**Composite Action** = step-level reuse. It replaces common Jenkins Shared Library steps such as Java setup, Maven build and test.

**Reusable Workflow** = job/pipeline-level reuse. It defines the organization's standard CI structure and consumes the Composite Action.

This separation lets hundreds of application repositories use the same platform standard without copying the pipeline.

## Artifact reuse and promotion

The CI workflow produces:

`springboot-build-<GITHUB_SHA>`

The promotion workflow accepts the original CI `run-id` and `image-tag`, then downloads the exact artifact from that run. It does not rebuild the application.

For a real deployment, replace the final echo command with:

```bash
helm upgrade --install springboot-poc helm/springboot-poc   --set image.repository=<registry>/<image>   --set image.tag=<GIT_SHA>   --namespace <environment> --create-namespace
```

The important design is **build once, promote the same immutable artifact**.

## Production approval

Create a GitHub Environment named `production` and configure **Required reviewers** in repository settings. The `deploy-production` job targets that environment.

The approval is a platform control, not a boolean input. A user selecting `production` cannot bypass the Environment reviewer requirement.

For DEV, create an optional `development` Environment if environment-specific secrets are needed.

## Security and secrets

No credentials are committed to the repository.

Recommended production model:
- GitHub Secrets/Variables for non-sensitive configuration.
- GitHub OIDC for AWS: workflow requests an OIDC token and AWS IAM exchanges it for short-lived credentials.
- For other enterprise systems, integrate with the organization's approved secrets platform such as CyberArk.
- Keep permissions least-privilege. This POC uses `contents: read` and only grants `actions: read` where the promotion job needs to download an artifact from another run.
- Never use `permissions: write-all`.

Example AWS OIDC permissions:

```yaml
permissions:
  contents: read
  id-token: write
```

The IAM role trust policy should restrict the repository/branch or GitHub Environment.

## Jenkins to GitHub Actions mapping

| Jenkins | GitHub Actions |
|---|---|
| Jenkinsfile | Workflow / Reusable Workflow |
| Shared Library | Composite Action / Reusable Workflow |
| Agent | GitHub-hosted or self-hosted runner |
| Credentials | GitHub Secrets / OIDC / enterprise secret manager |
| stash/unstash | upload-artifact / download-artifact |
| input | GitHub Environment required reviewers |
| `sh` | `run` |
| Jenkins parameters | `workflow_dispatch` inputs |
| Parallel stages | Multiple jobs / `parallel` matrix |
| Archived artifacts | Actions Artifacts |

## Jenkins pipeline

The sample Jenkinsfile follows the same stages:
Checkout -> Build/Test -> Security/Quality -> Docker Build -> Artifact -> DEV -> Production Approval -> Production.

The `jenkins/vars` directory represents the Shared Library. `buildAndTest.groovy`, `securityScan.groovy`, `qualityScan.groovy`, `buildAndPushImage.groovy`, `publishArtifact.groovy`, and `deployWithHelm.groovy` are reusable functions.

For a real Jenkins deployment, configure the required tools and credentials in Jenkins. The POC deliberately does not hardcode registry or cluster credentials.

## Scaling to hundreds of repositories

### 1. Centralize the standard

Put reusable workflows and Composite Actions in a platform repository, for example:

`company/devops-platform/.github/workflows/reusable-ci.yml@v1`

Application repositories should contain only thin caller workflows and application-specific configuration.

### 2. Version reusable components

Do not make every application depend on `main`.

Use immutable releases/tags:
- `@v1` for compatible changes
- `@v2` for breaking changes
- Pin to a commit SHA where the organization's security policy requires it

Test v2 against a pilot set before broad rollout.

### 3. Centralized standards

Enforce organization rulesets, required workflows, CODEOWNERS, approved actions and standard permissions. Keep the platform repository owned by a central DevOps/platform team.

### 4. Secrets

Prefer OIDC for cloud authentication because it removes long-lived cloud keys. Use GitHub Environments for environment-specific approvals/secrets. Integrate CyberArk or another enterprise secret manager where required.

### 5. Self-hosted runners

Use runner groups to isolate workloads, restrict repositories that can use them, and apply network controls. For sensitive workloads use ephemeral runners so secrets and workspace data do not persist between jobs.

### 6. Caching and parallelism

Use Maven/Gradle/npm caches through setup actions. Run independent security and quality checks in parallel. Use matrices for repeated combinations such as Java versions or application modules.

### 7. Jenkins migration strategy

A practical migration sequence:

1. Inventory all Jenkins jobs and Shared Library usage.
2. Categorize pipelines by pattern and complexity.
3. Build the central reusable workflow and Composite Actions.
4. Pilot 3–5 representative applications.
5. Run Jenkins and GitHub Actions in parallel for a short validation period.
6. Migrate in waves, prioritizing standardized pipelines.
7. Measure build duration, failure rate and deployment success.
8. Freeze new Jenkins jobs.
9. Retire Jenkins jobs after business sign-off.

**Key principle:** standardize common logic first, then migrate repositories in waves.

## Important POC boundary

The CI path is designed to execute on a normal public GitHub-hosted `ubuntu-latest` runner without private infrastructure. Docker is built locally and the exact build artifact is retained. The promotion workflow downloads that artifact and calls `scripts/deploy.sh`.

`deploy.sh` has two modes:
- With Kubernetes access, it performs a real `helm upgrade --install`.
- Without Kubernetes access, it performs Helm lint/template validation and exits successfully.

This makes the POC runnable for an evaluator while keeping the real deployment path in the repository. For a real DEV/PROD deployment, add registry authentication (prefer OIDC), Kubernetes access, and environment-specific permissions.

## Interview demonstration

1. Push the repository to GitHub.
2. Show `ci.yml` calling `reusable-ci.yml`.
3. Open the Composite Action and explain that it replaces Shared Library build/test logic.
4. Run the workflow and show Maven test, Helm lint, Trivy and Docker build.
5. Show the uploaded JAR/manifest artifact.
6. Copy the run ID and SHA into `workflow_dispatch` for DEV promotion.
7. Show the `production` Environment required reviewer configuration.
8. Show the Jenkinsfile and `jenkins/vars` side-by-side with the GitHub workflow.
9. Explain how the same reusable workflow can be versioned and consumed by hundreds of repositories.

## Architecture

See `docs/architecture.md`.
