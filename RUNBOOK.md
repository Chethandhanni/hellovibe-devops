\# RUNBOOK.md



\# HelloVibe Production Incident Runbook



\## Incident scenario



\- \*\*01:50:\*\* A new application version is deployed to production.

\- \*\*02:00:\*\* An alert fires, and approximately one-third of requests return HTTP 5xx errors.

\- \*\*Impact:\*\* Users may experience failed requests or intermittent service errors.

\- \*\*Priority:\*\* High. Investigate immediately and restore the last known good version if the deployment is responsible.



\## First 15 minutes



\### Minutes 0–2: Acknowledge and assess



1\. Acknowledge the alert in the monitoring system.

2\. Open Grafana and Prometheus to review the alert, error rate, request traffic, and application health.

3\. Confirm the affected environment is production.

4\. Notify the responsible team and begin recording the incident timeline.



\### Minutes 2–5: Check application health



Run:



```bash

kubectl get deployments -n prod

kubectl get pods -n prod -o wide

kubectl get events -n prod --sort-by=.lastTimestamp

```



Check application logs:



```bash

kubectl logs -n prod deployment/hellovibe-api --since=15m

```



Look for application exceptions, failed dependencies, configuration errors, failed probes, and container restarts.



\### Minutes 5–8: Correlate the deployment



1\. Identify the image tag or Git commit deployed at 01:50.

2\. Compare the error rate before and after the release.

3\. Check `/healthz`, `/version`, and application logs.

4\. Inspect recent changes to application code, environment variables, secrets, and dependencies.



If the errors began immediately after the deployment, treat the release as a likely cause until evidence shows otherwise.



\### Minutes 8–12: Mitigate



If the new release is responsible and a previous known-good Helm revision exists, roll back:



```bash

helm history hellovibe-api -n prod

helm rollback hellovibe-api <PREVIOUS\_REVISION> -n prod --wait --timeout=180s

```



Replace `<PREVIOUS\_REVISION>` with the verified last known good revision.



Then check rollout status:



```bash

kubectl rollout status deployment/hellovibe-api -n prod --timeout=180s

kubectl get deployments -n prod

```



If rollback is unavailable or fails, stop further releases and escalate to the platform or application owner.



\### Minutes 12–15: Verify recovery



1\. Check `/healthz` and `/version` using the production access method.

2\. Review the HTTP 5xx rate in Prometheus or Grafana.

3\. Confirm the expected replicas are available.

4\. Verify that the error rate is decreasing and normal requests succeed.

5\. Record the mitigation, affected release SHA, timestamps, and remaining risks.



\## Useful Prometheus queries



Request error ratio, if the application exposes the corresponding HTTP request counter:



```promql

sum(rate(http\_requests\_total{status=\~"5.."}\[5m]))

/

clamp\_min(sum(rate(http\_requests\_total\[5m])), 1)

```



Available production replicas:



```promql

kube\_deployment\_status\_replicas\_available{

&#x20; namespace="prod",

&#x20; deployment="hellovibe-api"

}

```



\*\*Note:\*\* The HTTP metric names and labels must match the metrics actually exposed by the application. Validate the query before using it during an incident.



\## Escalation and follow-up



\- Escalate if errors persist after rollback or if the root cause is unclear.

\- Preserve logs, deployment history, metrics, and the incident timeline.

\- After recovery, investigate the root cause, add regression tests, and improve release validation.

\- Do not close the incident until service health is verified and stakeholders are informed.

