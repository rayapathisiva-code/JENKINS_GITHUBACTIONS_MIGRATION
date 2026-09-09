# Architecture

```text
                         +----------------------+
                         | Application Repository|
                         | Spring Boot + Docker  |
                         +----------+-----------+
                                    |
                     +--------------v---------------+
                     | Application Workflow (ci.yml)|
                     +--------------+---------------+
                                    |
                     +--------------v---------------+
                     | Reusable Workflow            |
                     | reusable-ci.yml              |
                     +------+-----------------------+
                            |
              +-------------v--------------+
              | Composite Action           |
              | Maven build/test + cache   |
              +-------------+--------------+
                            |
       +--------------------+---------------------+
       |                    |                     |
   Quality              Security             Docker build
   Helm lint            Trivy FS             Git SHA tag
       |                    |                     |
       +--------------------+---------------------+
                            |
                     Upload build artifact
                            |
                  +---------v---------+
                  | DEV Environment   |
                  +---------+---------+
                            |
                    Production approval
                  GitHub Environment gate
                            |
                  +---------v---------+
                  | PROD Environment  |
                  +-------------------+

Jenkins path:
Jenkinsfile -> Shared Library -> Build/Test -> Quality/Security -> Docker -> Artifact -> Deploy
