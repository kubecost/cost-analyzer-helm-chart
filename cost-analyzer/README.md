# Kubecost helm chart
Helm chart for the Kubecost project, which is created to monitor and manage Kubernetes resource spend. Please contact team@kubecost.com or visit [kubecost.com](http://kubecost.com) for more info.

While Helm is the [recommended install path](http://kubecost.com/install), these resources can also be deployed with the following command:<a name="manifest"></a>

`kubectl apply -f https://raw.githubusercontent.com/kubecost/cost-analyzer-helm-chart/master/kubecost.yaml --namespace kubecost`

<a name="config-options"></a><br/>
## Parameters

### Prometheus

| Name                                                  | Description                                                                                                    | Value                                                |
| ----------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------- |
| `global.prometheus.enabled`                           | If false, Prometheus will not be installed -- only actively supported on paid Kubecost plans                   | `true`                                               |
| `global.prometheus.fqdn`                              | example address of a prometheus to connect to. Include protocol (http:// or https://) Ignored if enabled: true | `http://cost-analyzer-prometheus-server.default.svc` |
| `global.prometheus.insecureSkipVerify`                | If true, kubecost will not check the TLS cert of prometheus                                                    |                                                      |
| `global.prometheus.queryServiceBasicAuthSecretName`   | kubectl create secret generic dbsecret -n kubecost --from-file=USERNAME --from-file=PASSWORD                   | `""`                                                 |
| `global.prometheus.queryServiceBearerTokenSecretName` | kubectl create secret generic mcdbsecret -n kubecost --from-file=TOKEN                                         | `""`                                                 |
| `prometheus.kube-state-metrics.disabled`              | If false, deploy [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics) for Kubernetes metrics |                                                      |
| `prometheus.kube-state-metrics.resources`             | Set kube-state-metrics resource requests and limits.                                                           | `{}`                                                 |
| `prometheus.server.resources`                         | Prometheus server resource requests and limits.                                                                | `{}`                                                 |
| `prometheus.server.retention`                         | Determines when to remove old data.                                                                            | `{}`                                                 |
| `prometheus.server.persistentVolume.enabled`          | If true, Prometheus server will create a Persistent Volume Claim.                                              | `true`                                               |
| `prometheus.server.persistentVolume.size`             | Prometheus server data Persistent Volume size. Default set to retain ~6000 samples per second for 15 days.     | `32Gi`                                               |
| `prometheus.alertmanager.persistentVolume.enabled`    | If true, Alertmanager will create a Persistent Volume Claim.                                                   | `true`                                               |
| `prometheus.nodeExporter.enabled`                     | If false, do not create NodeExporter daemonset.                                                                | `true`                                               |
| `prometheus.nodeExporter.resources`                   | Node exporter resource requests and limits.                                                                    | `{}`                                                 |
| `prometheus.pushgateway.persistentVolume.enabled`     | If true, Prometheus Pushgateway will create a Persistent Volume Claim.                                         | `true`                                               |


### Thanos

| Name                                                   | Description                                                                                                                       | Value   |
| ------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------- | ------- |
| `global.thanos.enabled`                                | Enable Thanos sub-chart to be installed -- only supported on paid Kubecost plans                                                  | `false` |
| `global.thanos.queryService`                           | an address of the thanos query-frontend endpoint, if different from installed thanos                                              | `""`    |
| `global.thanos.queryServiceBasicAuthSecretNamekubectl` | create secret generic mcdbsecret -n kubecost --from-file=USERNAME --from-file=PASSWORD <---enter basic auth credentials like that | `""`    |
| `global.thanos.queryServiceBearerTokenSecretName`      | kubectl create secret generic mcdbsecret -n kubecost --from-file=TOKEN                                                            | `""`    |
| `global.thanos.queryOffset`                            | The offset to apply to all thanos queries in order to achieve syncronization on all cluster block stores                          | `""`    |


### Grafana

| Name                                                   | Description                                                                            | Value                               |
| ------------------------------------------------------ | -------------------------------------------------------------------------------------- | ----------------------------------- |
| `global.grafana.enabled`                               | If false, Grafana will not be installed                                                | `true`                              |
| `global.grafana.domainName`                            | example grafana domain Ignored if enabled: true                                        | `cost-analyzer-grafana.default.svc` |
| `global.grafana.scheme`                                | http or https, for the domain name above.                                              | `http`                              |
| `global.grafana.proxy`                                 | If true, the kubecost frontend will route to your grafana through its service endpoint | `true`                              |
| `grafana.resources`                                    | Grafana resource requests and limits.                                                  | `{}`                                |
| `grafana.sidecar.datasources.defaultDatasourceEnabled` | Set this to `false` to disable creation of Prometheus datasource in Grafana            | `false`                             |


### Kubecost Application Configuration

| Name                                                      | Description                                                                                               | Value                                                |
| --------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- | ---------------------------------------------------- |
| `global.notifications`                                    | Kubecost notification settings                                                                            |                                                      |
| `global.notifications.alertConfigs`                       | Kubecost alerting configuration                                                                           | `{}`                                                 |
| `global.notifications.alertConfigs.frontendUrl`           | optional, used for linkbacks                                                                              | `""`                                                 |
| `global.notifications.alertConfigs.globalSlackWebhookUrl` | optional, used for Slack alerts                                                                           | `""`                                                 |
| `global.notifications.alertConfigs.globalAlertEmails`     | optional, array of emails to use for Email alerts                                                         | `[]`                                                 |
| `global.notifications.alertConfigs.alerts`                | Alerts generated by kubecost, about cluster data                                                          | `[]`                                                 |
| `global.notifications.alertmanager.enabled`               | If true, allow kubecost to write to your alertmanager                                                     | `false`                                              |
| `global.notifications.alertmanager.fqdn`                  | example fqdn. Ignored if prometheus.enabled: true                                                         | `http://cost-analyzer-prometheus-server.default.svc` |
| `global.savedReports`                                     | Set saved allocation report(s) accessible from reports.html (Ref: http://docs.kubecost.com/saved-reports) |                                                      |
| `global.savedReports.enabled`                             | If true, overwrites report parameters set through UI                                                      | `false`                                              |
| `global.savedReports.reports`                             | List of reports to create on pod startup                                                                  | `[]`                                                 |
| `global.assetReports`                                     | Set saved asset report(s) accessible from reports.html (Ref: http://docs.kubecost.com/saved-reports)      |                                                      |
| `global.assetReports.enabled`                             | If true, overwrites report parameters set through UI                                                      | `false`                                              |
| `global.assetReports.reports`                             | List of reports to create on pod startup                                                                  | `[]`                                                 |
| `kubecostToken`                                           | generated at http://kubecost.com/install, used for alerts tracking and free trials                        | `""`                                                 |
| `pricingCsv.enabled`                                      | Enable advanced pipeline for custom prices, enterprise key required                                       | `false`                                              |
| `pricingCsv.location.provider`                            | Provider for custom prices pipeline                                                                       | `AWS`                                                |
| `pricingCsv.location.region`                              | Region for custom prices pipeline                                                                         | `us-east-1`                                          |
| `pricingCsv.location.URI`                                 | a valid file URI                                                                                          | `s3://kc-csv-test/pricing_schema.csv`                |
| `pricingCsv.location.csvAccessCredentials`                | Access credentials for custom prices pipeline                                                             | `pricing-schema-access-secret`                       |
| `saml`                                                    | SAML integration for user management and RBAC, enterprise key required                                    | `{}`                                                 |


### Kubecost Deployment Configuration

| Name                                          | Description                                                                                                                                                                         | Value                     |
| --------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------- |
| `global.podAnnotations`                       | Additional annotations to add to to resources deployed by the chart                                                                                                                 | `{}`                      |
| `global.additionalLabels`                     | Additional labels to add to to resources deployed by the chart                                                                                                                      | `{}`                      |
| `ingress.enabled`                             | If true, Ingress will be created                                                                                                                                                    | `false`                   |
| `ingress.annotations`                         | Ingress annotations                                                                                                                                                                 | `nil`                     |
| `ingress.paths`                               | Ingress paths                                                                                                                                                                       | `["/"]`                   |
| `ingress.hosts`                               | Ingress hostnames                                                                                                                                                                   | `["cost-analyzer.local"]` |
| `ingress.tls`                                 | Ingress TLS configuration (YAML)                                                                                                                                                    | `[]`                      |
| `tolerations`                                 | node taints to tolerate                                                                                                                                                             | `[]`                      |
| `affinity`                                    | pod affinity                                                                                                                                                                        | `{}`                      |
| `priority.enabled`                            | If true, creates a PriorityClass to be used by the cost-analyzer pod                                                                                                                | `false`                   |
| `networkPolicy.enabled`                       | If true, create a NetworkPolicy to deny egress                                                                                                                                      | `false`                   |
| `networkPolicy.costAnalyzer.enabled`          | If true, create a newtork policy for cost-analzyer                                                                                                                                  | `false`                   |
| `networkPolicy.costAnalyzer.annotations`      | Annotations to be added to the network policy                                                                                                                                       | `{}`                      |
| `networkPolicy.costAnalyzer.additionalLabels` | Additional labels to be added to the network policy                                                                                                                                 | `{}`                      |
| `networkPolicy.costAnalyzer.ingressRules`     | A list of network policy ingress rules                                                                                                                                              | `[]`                      |
| `networkPolicy.costAnalyzer.egressRules`      | A list of network policy egress rules                                                                                                                                               | `[]`                      |
| `extraVolumes`                                | A list of volumes to be added to the pod                                                                                                                                            | `[]`                      |
| `extraVolumeMounts`                           | A list of volume mounts to be added to the pod                                                                                                                                      | `[]`                      |
| `persistentVolume.enabled`                    | If true, Kubecost will create a Persistent Volume Claim for product config data.                                                                                                    | `true`                    |
| `persistentVolume.size`                       | Define PVC size for cost-analyzer                                                                                                                                                   | `32Gi`                    |
| `persistentVolume.dbSize`                     | Define PVC size for cost-analyzer's flat file database                                                                                                                              | `32.0Gi`                  |
| `networkCosts.enabled`                        | If true, collect network allocation metrics [More info](http://docs.kubecost.com/network-allocation)                                                                                | `false`                   |
| `networkCosts.podMonitor.enabled`             | If true, a [PodMonitor](https://github.com/coreos/prometheus-operator/blob/master/Documentation/api.md#podmonitor) for the network-cost daemonset is created                        | `false`                   |
| `kubecostDeployment.replicas`                 | Used for HA mode in Business & Enterprise tier                                                                                                                                      | `1`                       |
| `clusterController.enabled`                   | If true, enable the Kubecost Cluster Controller for Right Sizing and Cluster Turndown                                                                                               | `false`                   |
| `serviceMonitor.enabled`                      | Set this to true to create ServiceMonitor for Prometheus operator                                                                                                                   | `false`                   |
| `serviceMonitor.additionalLabels`             | Additional labels that can be used so ServiceMonitor will be discovered by Prometheus                                                                                               | `{}`                      |
| `prometheusRule.enabled`                      | Set this to `true` to create PrometheusRule for Prometheus operator                                                                                                                 | `false`                   |
| `prometheusRule.additionalLabels`             | Additional labels that can be used so PrometheusRule will be discovered by Prometheus                                                                                               | `{}`                      |
| `initChownDataImage`                          | Ensures all Kubecost filepath permissions on PV or local storage are set up correctly. Supports a fully qualified Docker image, e.g. registry.hub.docker.com/library/busybox:latest | `busybox`                 |
| `serviceAccount.create`                       | Set this to `false` if you want to create the service account `kubecost-cost-analyzer` on your own                                                                                  | `true`                    |


