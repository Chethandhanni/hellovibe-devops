\# DESIGN.md



\# HelloVibe DevOps Take-Home: Architecture and Design



\## Overview



HelloVibe is a containerized HTTP service supported by reusable Terraform infrastructure, Helm-based Kubernetes deployments, CI/CD automation, and Prometheus/Grafana monitoring. The design emphasizes repeatability, immutable image versions, security, and recovery from failed releases.



\## Architecture



\### Application



The Flask service exposes `/healthz` for health checks, `/version` for the Git commit identifier, and `/metrics` for Prometheus metrics. The multi-stage Docker build separates dependency installation from the runtime image. The application runs as a non-root user.



\### Infrastructure as Code



Terraform modules separate networking, application infrastructure, and observability. Development and production environments reuse the modules with environment-specific settings. Azure resources include networking, Log Analytics, Container Apps, managed identity, and Key Vault configuration. Remote state and state locking are documented for shared deployments.



\### Kubernetes and Helm



The application is packaged as a reusable Helm chart and deployed into separate development and production namespaces. Deployments configure readiness and liveness probes, CPU and memory requests and limits, rolling updates, and autoscaling. Production is configured for at least two replicas.



Terraform manages local Kubernetes namespaces and Helm releases. The kube-prometheus-stack Helm chart installs Prometheus, Grafana, and Alertmanager. A custom PrometheusRule alerts when fewer than two production replicas are available.



\### CI/CD workflow



GitHub Actions validates Terraform, runs Terraform tests and static checks, builds the application image, and scans it with Trivy. On pushes to `main`, the pipeline publishes an image to GitHub Container Registry tagged with the Git commit SHA.



The same immutable image is deployed to development and smoke-tested before production promotion. A protected GitHub Environment requires production approval. The production job runs smoke tests and attempts Helm rollback on failure.



\## Security decisions



\- Run the application as a non-root user.

\- Use immutable Git SHA image tags instead of relying on mutable `latest` tags.

\- Scan container images and infrastructure configuration.

\- Use Kubernetes namespaces to separate development, production, and monitoring.

\- Use managed identity and Key Vault RBAC for Azure application access.

\- Protect production promotion with an approval gate.

\- Avoid committing credentials or secrets to source control.



\## Observability and recovery



Prometheus collects Kubernetes and application metrics. Grafana provides dashboards, and Alertmanager provides alert-routing capability. The custom replica alert detects reduced production availability. The runbook documents triage, deployment correlation, rollback, and recovery verification.



\## Trade-offs and limitations



Local Kubernetes testing provides a repeatable development workflow but does not represent a persistent production cluster. The CI workflow's temporary kind clusters demonstrate deployment and rollback behavior within each run. A real production platform would need persistent infrastructure, durable release history, centralized logs, secure secret management, and tested alert delivery.



Security scanners may report unfixed upstream operating-system vulnerabilities. These findings must be reviewed and tracked rather than assumed resolved. Azure infrastructure is validated through Terraform configuration and tests; actual cloud deployment requires the appropriate Azure credentials and environment setup.



\## Future improvements



\- Add integration tests and automated rollback tests.

\- Add durable deployment history and rollback verification.

\- Configure alert delivery to an operational notification channel.

\- Add dashboards for latency, throughput, error rate, and saturation.

\- Add persistent monitoring storage, retention policies, and backup procedures.

