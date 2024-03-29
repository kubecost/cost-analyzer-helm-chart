{{/* vim: set filetype=mustache: */}}

{{/*
Set important variables before starting main templates
*/}}
{{- define "aggregator.deployMethod" -}}
  {{- if (.Values.federatedETL).primaryCluster }}
    {{- printf "statefulset" }}
  {{- else if or ((.Values.federatedETL).agentOnly) (.Values.agent) (.Values.cloudAgent) }}
    {{- printf "disabled" }}
  {{- else if (not .Values.kubecostAggregator) }}
    {{- printf "singlepod" }}
  {{- else if .Values.kubecostAggregator.enabled }}
    {{- printf "statefulset" }}
  {{- else if eq .Values.kubecostAggregator.deployMethod "singlepod" }}
    {{- printf "singlepod" }}
  {{- else if eq .Values.kubecostAggregator.deployMethod "statefulset" }}
    {{- printf "statefulset" }}
  {{- else if eq .Values.kubecostAggregator.deployMethod "disabled" }}
    {{- printf "disabled" }}
  {{- else }}
    {{- fail "Unknown kubecostAggregator.deployMethod value" }}
  {{- end }}
{{- end }}

{{- define "frontend.deployMethod" -}}
  {{- if eq .Values.kubecostFrontend.deployMethod "haMode" -}}
    {{- printf "haMode" -}}
  {{- else -}}
    {{- printf "singlepod" -}}
  {{- end -}}
{{- end -}}

{{/*
Kubecost 2.0 preconditions
*/}}
{{- define "kubecostV2-preconditions" -}}
  {{/* Iterate through all StatefulSets in the namespace and check if any of them have a label indicating they are from
  a pre-2.0 Helm Chart (e.g. "helm.sh/chart: cost-analyzer-1.108.1"). If so, return an error message with details and
  documentation for how to properly upgrade to Kubecost 2.0 */}}
  {{- $sts := (lookup "apps/v1" "StatefulSet" .Release.Namespace "") -}}
  {{- if not (empty $sts.items) -}}
    {{- range $index, $sts := $sts.items -}}
      {{- if contains "aggregator" $sts.metadata.name -}}
        {{- if $sts.metadata.labels -}}
          {{- $stsLabels := $sts.metadata.labels -}}                  {{/* helm.sh/chart: cost-analyzer-1.108.1 */}}
          {{- if hasKey $stsLabels "helm.sh/chart" -}}
            {{- $chartLabel := index $stsLabels "helm.sh/chart" -}}   {{/* cost-analyzer-1.108.1 */}}
            {{- $chartNameAndVersion := split "-" $chartLabel -}}     {{/* _0:cost _1:analyzer _2:1.108.1 */}}
            {{- if gt (len $chartNameAndVersion) 2 -}}
              {{- $chartVersion := $chartNameAndVersion._2 -}}        {{/* 1.108.1 */}}
              {{- if semverCompare ">=1.0.0-0 <2.0.0-0" $chartVersion -}}
                {{- fail "\n\nAn existing Aggregator StatefulSet was found in your namespace.\nBefore upgrading to Kubecost 2.x, please `kubectl delete` this Statefulset.\nRefer to the following documentation for more information: https://docs.kubecost.com/install-and-configure/install/kubecostv2" -}}
              {{- end -}}
            {{- end -}}
          {{- end -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{/*https://github.com/helm/helm/issues/8026#issuecomment-881216078*/}}
  {{- if ((.Values.thanos).store).enabled -}}
    {{- fail "\n\nYou are attempting to upgrade to Kubecost 2.x.\nKubecost no longer includes Thanos by default. \nPlease see https://docs.kubecost.com/install-and-configure/install/kubecostv2 for more information.\nIf you have any questions or concerns, please reach out to us at product@kubecost.com" -}}
  {{- end -}}

  {{- if or (((.Values.global).amp).enabled) (((.Values.global).gmp).enabled) (((.Values.global).thanos).queryService) (((.Values.global).mimirProxy).enabled) -}}
    {{- if (not (.Values.federatedETL).federatedCluster)  -}}
      {{- if (not (.Values.upgrade).toV2) -}}
      {{- fail "\n\nMulti-Cluster-Prometheus Error:\nYou are attempting to upgrade to Kubecost 2.x\nSupport for multi-cluster Prometheus (Thanos/AMP/GMP/mimir/etc) without using `Kubecost Federated ETL Object Storage` will be added in future release. \nIf this is a single cluster Kubecost environment, upgrading is supported using a flag to acknowledge this change.\nMore information can be found here: \nhttps://docs.kubecost.com/install-and-configure/install/kubecostv2\nIf you have any questions or concerns, please reach out to us at product@kubecost.com\n\nWhen ready to upgrade, add `--set upgrade.toV2=true`." -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{- if or ((.Values.saml).rbac).enabled ((.Values.oidc).rbac).enabled -}}
    {{- if (not (.Values.upgrade).toV2) -}}
      {{- fail "\n\nSSO with RBAC is enabled.\nNote that Kubecost 2.x has significant architectural changes that may impact RBAC.\nThis should be tested before giving end-users access to the UI.\nKubecost has tested various configurations and believe that 2.x will be 100% compatible with existing configurations.\nRefer to the following documentation for more information: https://docs.kubecost.com/install-and-configure/install/kubecostv2\n\nWhen ready to upgrade, add `--set upgrade.toV2=true`." -}}
    {{- end -}}
  {{- end -}}

  {{- if not .Values.kubecostModel.etlFileStoreEnabled -}}
    {{- fail "\n\nKubecost 2.0 does not support running fully in-memory. Some file system must be available to store cost data." -}}
  {{- end -}}


  {{- if (.Values.agent) -}}
    {{- fail "\n\nKubecost 2.0 Does not support Thanos based agents. For Thanos, please continue to use 1.108.x.\nConsider moving to Kubecost Federated ETL based agents.\nRefer to the following documentation for more information: https://docs.kubecost.com/install-and-configure/install/kubecostv2\nSupport for Thanos agents is under consideration.\nIf you have any questions or concerns, please reach out to us at product@kubecost.com" -}}
  {{- end -}}
  {{- if .Values.kubecostModel.openSourceOnly -}}
    {{- fail "In Kubecost 2.0, kubecostModel.openSourceOnly is not supported" -}}
  {{- end -}}

  {{/* Aggregator config reconciliation and common config */}}
  {{- if eq (include "aggregator.deployMethod" .) "statefulset" -}}
    {{- if .Values.kubecostAggregator -}}
      {{- if (not .Values.kubecostAggregator.aggregatorDbStorage) -}}
        {{- fail "In Enterprise configuration, Aggregator DB storage is required" -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{- if (.Values.podSecurityPolicy).enabled }}
    {{- fail "Kubecost no longer includes PodSecurityPolicy by default. Please take steps to preserve your existing PSPs before attempting the installation/upgrade again with the podSecurityPolicy values removed." }}
  {{- end }}

  {{- if ((.Values.kubecostDeployment).leaderFollower).enabled -}}
    {{- fail "\nIn Kubecost 2.0, kubecostDeployment does not support running as leaderFollower. Please reach out to support to discuss upgrade paths." -}}
  {{- end -}}

  {{- if ((.Values.kubecostDeployment).statefulSet).enabled -}}
    {{- fail "\nIn Kubecost 2.0, kubecostDeployment does not support running as a statefulSet. Please reach out to support to discuss upgrade paths." -}}
  {{- end -}}
  {{- if and (eq (include "aggregator.deployMethod" .) "statefulset") (.Values.federatedETL).agentOnly }}
    {{- fail "\nKubecost does not support running federatedETL.agentOnly with the aggregator statefulset" }}
  {{- end }}
{{- end -}}

{{- define "cloudIntegrationFromProductConfigs" }}
  {
    {{- if ((.Values.kubecostProductConfigs).athenaBucketName) }}
    "aws": [
      {
          "athenaBucketName": "{{ .Values.kubecostProductConfigs.athenaBucketName }}",
          "athenaRegion": "{{ .Values.kubecostProductConfigs.athenaRegion }}",
          "athenaDatabase": "{{ .Values.kubecostProductConfigs.athenaDatabase }}",
          "athenaTable": "{{ .Values.kubecostProductConfigs.athenaTable }}",
          "projectID": "{{ .Values.kubecostProductConfigs.athenaProjectID }}"
          {{ if (.Values.kubecostProductConfigs).athenaWorkgroup }}
          , "athenaWorkgroup": "{{ .Values.kubecostProductConfigs.athenaWorkgroup }}"
          {{ else }}
          , "athenaWorkgroup": "primary"
          {{ end }}
          {{ if (.Values.kubecostProductConfigs).masterPayerARN }}
          , "masterPayerARN": "{{ .Values.kubecostProductConfigs.masterPayerARN }}"
          {{ end }}
          {{- if and ((.Values.kubecostProductConfigs).awsServiceKeyName) ((.Values.kubecostProductConfigs).awsServiceKeyPassword) }},
          "serviceKeyName": "{{ .Values.kubecostProductConfigs.awsServiceKeyName }}",
          "serviceKeySecret": "{{ .Values.kubecostProductConfigs.awsServiceKeyPassword }}"
          {{- end }}
      }
    ]
    {{- end }}
  }
{{- end }}

{{/*
Cloud integration source contents check. Either the Secret must be specified or the JSON, not both.
Additionally, for upgrade protection, certain individual values populated under the kubecostProductConfigs map, if found,
will result in failure. Users are asked to select one of the two presently-available sources for cloud integration information.
*/}}
{{- define "cloudIntegrationSourceCheck" -}}
  {{- if and (.Values.kubecostProductConfigs).cloudIntegrationSecret (.Values.kubecostProductConfigs).cloudIntegrationJSON -}}
    {{- fail "\nkubecostProductConfigs.cloudIntegrationSecret and kubecostProductConfigs.cloudIntegrationJSON are mutually exclusive. Please specify only one." -}}
  {{- end -}}
  {{- if and (.Values.kubecostProductConfigs).cloudIntegrationSecret ((.Values.kubecostProductConfigs).athenaBucketName) }}
    {{- fail "\nkubecostProductConfigs.cloudIntegrationSecret and kubecostProductConfigs.athena* values are mutually exclusive. Please specifiy only one." -}}
  {{- end -}}
{{- if and (.Values.kubecostProductConfigs).cloudIntegrationJSON ((.Values.kubecostProductConfigs).athenaBucketName) }}
    {{- fail "\nkubecostProductConfigs.cloudIntegrationJSON and kubecostProductConfigs.athena* values are mutually exclusive. Please specifiy only one." -}}
  {{- end -}}
{{- end -}}


{{/*
Print a warning if PV is enabled AND EKS is detected AND the EBS-CSI driver is not installed
*/}}
{{- define "eksCheck" }}
{{- $isEKS := (regexMatch ".*eks.*" (.Capabilities.KubeVersion | quote) )}}
{{- $isGT22 := (semverCompare ">=1.23-0" .Capabilities.KubeVersion.GitVersion) }}
{{- $PVNotExists := (empty (lookup "v1" "PersistentVolume" "" "")) }}
{{- $EBSCSINotExists := (empty (lookup "apps/v1" "Deployment" "kube-system" "ebs-csi-controller")) }}
{{- if (and $isEKS $isGT22 .Values.persistentVolume.enabled $EBSCSINotExists) -}}

ERROR: MISSING EBS-CSI DRIVER WHICH IS REQUIRED ON EKS v1.23+ TO MANAGE PERSISTENT VOLUMES. LEARN MORE HERE: https://docs.kubecost.com/install-and-configure/install/provider-installations/aws-eks-cost-monitoring#prerequisites

{{- end -}}
{{- end -}}

{{/*
Verify the cloud integration secret exists with the expected key when cloud integration is enabled.
Skip the check if CI/CD is enabled and skipSanityChecks is set. Argo CD, for example, does not
support templating a chart which uses the lookup function.
*/}}
{{- define "cloudIntegrationSecretCheck" -}}
{{- if (.Values.kubecostProductConfigs).cloudIntegrationSecret }}
{{- if not (and .Values.global.platforms.cicd.enabled .Values.global.platforms.cicd.skipSanityChecks) }}
{{-  if .Capabilities.APIVersions.Has "v1/Secret" }}
  {{- $secret := lookup "v1" "Secret" .Release.Namespace .Values.kubecostProductConfigs.cloudIntegrationSecret }}
  {{- if or (not $secret) (not (index $secret.data "cloud-integration.json")) }}
    {{- fail (printf "The cloud integration secret '%s' does not exist or does not contain the expected key 'cloud-integration.json'\nIf you are using `--dry-run`, please add `--dry-run=server`. This requires Helm 3.13+." .Values.kubecostProductConfigs.cloudIntegrationSecret) }}
  {{- end }}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Verify the federated storage config secret exists with the expected key when cloud integration is enabled.
Skip the check if CI/CD is enabled and skipSanityChecks is set. Argo CD, for example, does not
support templating a chart which uses the lookup function.
*/}}
{{- define "federatedStorageConfigSecretCheck" -}}
{{- if (.Values.kubecostModel).federatedStorageConfigSecret }}
{{- if not (and .Values.global.platforms.cicd.enabled .Values.global.platforms.cicd.skipSanityChecks) }}
{{-  if .Capabilities.APIVersions.Has "v1/Secret" }}
  {{- $secret := lookup "v1" "Secret" .Release.Namespace .Values.kubecostModel.federatedStorageConfigSecret }}
  {{- if or (not $secret) (not (index $secret.data "federated-store.yaml")) }}
    {{- fail (printf "The federated storage config secret '%s' does not exist or does not contain the expected key 'federated-store.yaml'" .Values.kubecostModel.federatedStorageConfigSecret) }}
  {{- end }}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
 Ensure that the Prometheus retention is not set too low
*/}}
{{- define "prometheusRetentionCheck" }}
{{- if ((.Values.prometheus).server).enabled }}

  {{- $retention := .Values.prometheus.server.retention }}
  {{- $etlHourlyDurationHours := (int .Values.kubecostModel.etlHourlyStoreDurationHours) }}

  {{- if (hasSuffix "d" $retention) }}
    {{- $retentionDays := (int (trimSuffix "d" $retention)) }}
    {{- if lt $retentionDays 3 }}
      {{- fail (printf "With a daily resolution, Prometheus retention must be set >= 3 days. Provided retention is %s" $retention) }}
    {{- else if le (mul $retentionDays 24) $etlHourlyDurationHours }}
      {{- fail (printf "Prometheus retention (%s) must be greater than .Values.kubecostModel.etlHourlyStoreDurationHours (%d)" $retention $etlHourlyDurationHours) }}
    {{- end }}

  {{- else if (hasSuffix "h" $retention) }}
    {{- $retentionHours := (int (trimSuffix "h" $retention)) }}
    {{- if lt $retentionHours 50 }}
      {{- fail (printf "With an hourly resolution, Prometheus retention must be set >= 50 hours. Provided retention is %s" $retention) }}
    {{- else if le $retentionHours $etlHourlyDurationHours }}
      {{- fail (printf "Prometheus retention (%s) must be greater than .Values.kubecostModel.etlHourlyStoreDurationHours (%d)" $retention $etlHourlyDurationHours) }}
    {{- end }}

  {{- else }}
    {{- fail "prometheus.server.retention must be set in days (e.g. 5d) or hours (e.g. 97h)"}}

  {{- end }}
{{- end }}
{{- end }}

{{/*
Expand the name of the chart.
*/}}
{{- define "cost-analyzer.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- define "aggregator.name" -}}
{{- default "aggregator" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- define "cloudCost.name" -}}
{{- default "cloud-cost" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- define "etlUtils.name" -}}
{{- default "etl-utils" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- define "forecasting.name" -}}
{{- default "forecasting" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- define "frontend.name" -}}
{{- default "frontend" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "cost-analyzer.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "diagnostics.fullname" -}}
{{- if .Values.diagnosticsFullnameOverride -}}
{{- .Values.diagnosticsFullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name "diagnostics" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "aggregator.fullname" -}}
{{- printf "%s-%s" .Release.Name "aggregator" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "cloudCost.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "cloudCost.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "etlUtils.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "etlUtils.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- define "forecasting.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "forecasting.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- define "frontend.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "frontend.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the fully qualified name for Prometheus server service.
*/}}
{{- define "cost-analyzer.prometheus.server.name" -}}
{{- if .Values.prometheus -}}
{{- if .Values.prometheus.server -}}
{{- if .Values.prometheus.server.fullnameOverride -}}
{{- .Values.prometheus.server.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-prometheus-server" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- else -}}
{{- printf "%s-prometheus-server" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- else -}}
{{- printf "%s-prometheus-server" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create the fully qualified name for Prometheus alertmanager service.
*/}}
{{- define "cost-analyzer.prometheus.alertmanager.name" -}}
{{- if .Values.prometheus -}}
{{- if .Values.prometheus.alertmanager -}}
{{- if .Values.prometheus.alertmanager.fullnameOverride -}}
{{- .Values.prometheus.alertmanager.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-prometheus-alertmanager" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- else -}}
{{- printf "%s-prometheus-alertmanager" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- else -}}
{{- printf "%s-prometheus-alertmanager" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "cost-analyzer.serviceName" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "frontend.serviceName" -}}
{{ include "frontend.fullname" . }}
{{- end -}}

{{- define "diagnostics.serviceName" -}}
{{- printf "%s-%s" .Release.Name "diagnostics" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- define "aggregator.serviceName" -}}
{{- printf "%s-%s" .Release.Name "aggregator" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- define "cloudCost.serviceName" -}}
{{ include "cloudCost.fullname" . }}
{{- end -}}
{{- define "etlUtils.serviceName" -}}
{{ include "etlUtils.fullname" . }}
{{- end -}}
{{- define "forecasting.serviceName" -}}
{{ include "forecasting.fullname" . }}
{{- end -}}

{{/*
Create the name of the service account
*/}}
{{- define "cost-analyzer.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "cost-analyzer.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}
{{- define "aggregator.serviceAccountName" -}}
{{- if .Values.kubecostAggregator.serviceAccountName -}}
    {{ .Values.kubecostAggregator.serviceAccountName }}
{{- else -}}
    {{ template "cost-analyzer.serviceAccountName" . }}
{{- end -}}
{{- end -}}
{{- define "cloudCost.serviceAccountName" -}}
{{- if .Values.kubecostAggregator.cloudCost.serviceAccountName -}}
    {{ .Values.kubecostAggregator.cloudCost.serviceAccountName }}
{{- else -}}
    {{ template "cost-analyzer.serviceAccountName" . }}
{{- end -}}
{{- end -}}
{{/*
Network Costs name used to tie autodiscovery of metrics to daemon set pods
*/}}
{{- define "cost-analyzer.networkCostsName" -}}
{{- printf "%s-%s" .Release.Name "network-costs" -}}
{{- end -}}

{{- define "kubecost.clusterControllerName" -}}
{{- printf "%s-%s" .Release.Name "cluster-controller" -}}
{{- end -}}

{{- define "kubecost.kubeMetricsName" -}}
{{- if .Values.agent }}
{{- printf "%s-%s" .Release.Name "agent" -}}
{{- else if .Values.cloudAgent }}
{{- printf "%s-%s" .Release.Name "cloud-agent" -}}
{{- else }}
{{- printf "%s-%s" .Release.Name "metrics" -}}
{{- end }}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "cost-analyzer.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the chart labels.
*/}}
{{- define "cost-analyzer.chartLabels" -}}
helm.sh/chart: {{ include "cost-analyzer.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
{{- define "kubecost.chartLabels" -}}
app.kubernetes.io/name: {{ include "cost-analyzer.name" . }}
helm.sh/chart: {{ include "cost-analyzer.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
{{- define "kubecost.aggregator.chartLabels" -}}
app.kubernetes.io/name: {{ include "aggregator.name" . }}
helm.sh/chart: {{ include "cost-analyzer.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}


{{/*
Create the common labels.
*/}}
{{- define "cost-analyzer.commonLabels" -}}
app.kubernetes.io/name: {{ include "cost-analyzer.name" . }}
helm.sh/chart: {{ include "cost-analyzer.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app: cost-analyzer
{{- end -}}

{{- define "aggregator.commonLabels" -}}
{{ include "cost-analyzer.chartLabels" . }}
app: aggregator
{{- end -}}

{{- define "diagnostics.commonLabels" -}}
{{ include "cost-analyzer.chartLabels" . }}
app: diagnostics
{{- end -}}

{{- define "cloudCost.commonLabels" -}}
{{ include "cost-analyzer.chartLabels" . }}
{{ include "cloudCost.selectorLabels" . }}
{{- end -}}

{{- define "etlUtils.commonLabels" -}}
{{ include "cost-analyzer.chartLabels" . }}
{{ include "etlUtils.selectorLabels" . }}
{{- end -}}
{{- define "forecasting.commonLabels" -}}
{{ include "cost-analyzer.chartLabels" . }}
{{ include "forecasting.selectorLabels" . }}
{{- end -}}

{{/*
Create the networkcosts common labels. Note that because this is a daemonset, we don't want app.kubernetes.io/instance: to take the release name, which allows the scrape config to be static.
*/}}
{{- define "networkcosts.commonLabels" -}}
app.kubernetes.io/instance: kubecost
app.kubernetes.io/name: network-costs
helm.sh/chart: {{ include "cost-analyzer.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app: {{ template "cost-analyzer.networkCostsName" . }}
{{- end -}}
{{- define "networkcosts.selectorLabels" -}}
app: {{ template "cost-analyzer.networkCostsName" . }}
{{- end }}
{{- define "diagnostics.selectorLabels" -}}
app.kubernetes.io/name: diagnostics
app.kubernetes.io/instance: {{ .Release.Name }}
app: diagnostics
{{- end }}

{{/*
Create the selector labels.
*/}}
{{- define "cost-analyzer.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cost-analyzer.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app: cost-analyzer
{{- end -}}

{{/*
Create the selector labels for haMode frontend.
*/}}
{{- define "frontend.selectorLabels" -}}
app.kubernetes.io/name: {{ include "frontend.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app: cost-analyzer
{{- end -}}

{{- define "aggregator.selectorLabels" -}}
{{- if eq (include "aggregator.deployMethod" .) "statefulset" }}
app.kubernetes.io/name: {{ include "aggregator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app: aggregator
{{- else if eq (include "aggregator.deployMethod" .) "singlepod" }}
{{- include "cost-analyzer.selectorLabels" . }}
{{- else }}
{{ fail "Failed to set aggregator.selectorLabels" }}
{{- end }}
{{- end }}

{{- define "cloudCost.selectorLabels" -}}
{{- if eq (include "aggregator.deployMethod" .) "statefulset" }}
app.kubernetes.io/name: {{ include "cloudCost.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app: {{ include "cloudCost.name" . }}
{{- else }}
{{- include "cost-analyzer.selectorLabels" . }}
{{- end }}
{{- end }}

{{- define "forecasting.selectorLabels" -}}
app.kubernetes.io/name: {{ include "forecasting.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app: {{ include "forecasting.name" . }}
{{- end -}}
{{- define "etlUtils.selectorLabels" -}}
app.kubernetes.io/name: {{ include "etlUtils.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app: {{ include "etlUtils.name" . }}
{{- end -}}

{{/*
Recursive filter which accepts a map containing an input map (.v) and an output map (.r). The template
will traverse all values inside .v recursively writing non-map values to the output .r. If a nested map
is discovered, we look for an 'enabled' key. If it doesn't exist, we continue traversing the
map. If it does exist, we omit the inner map traversal iff enabled is false. This filter writes the
enabled only version to the output .r
*/}}
{{- define "cost-analyzer.filter" -}}
{{- $v := .v }}
{{- $r := .r }}
{{- range $key, $value := .v }}
    {{- $tp := kindOf $value -}}
    {{- if eq $tp "map" -}}
        {{- $isEnabled := true -}}
        {{- if (hasKey $value "enabled") -}}
            {{- $isEnabled = $value.enabled -}}
        {{- end -}}
        {{- if $isEnabled -}}
            {{- $rr := "{}" | fromYaml }}
            {{- template "cost-analyzer.filter" (dict "v" $value "r" $rr) }}
            {{- $_ := set $r $key $rr -}}
        {{- end -}}
    {{- else -}}
        {{- $_ := set $r $key $value -}}
    {{- end -}}
{{- end -}}
{{- end -}}

{{/*
This template accepts a map and returns a base64 encoded json version of the map where all disabled
leaf nodes are omitted.

The implied use case is {{ template "cost-analyzer.filterEnabled" .Values }}
*/}}
{{- define "cost-analyzer.filterEnabled" -}}
{{- $result := "{}" | fromYaml }}
{{- template "cost-analyzer.filter" (dict "v" . "r" $result) }}
{{- $result | toJson | b64enc }}
{{- end -}}

{{/*
==============================================================
Begin Prometheus templates
==============================================================
*/}}
{{/*
Expand the name of the chart.
*/}}
{{- define "prometheus.name" -}}
{{- "prometheus" -}}
{{- end -}}

{{/*
Define common selector labels for all Prometheus components
*/}}
{{- define "prometheus.common.matchLabels" -}}
app: {{ template "prometheus.name" . }}
release: {{ .Release.Name }}
{{- end -}}

{{/*
Define common top-level labels for all Prometheus components
*/}}
{{- define "prometheus.common.metaLabels" -}}
heritage: {{ .Release.Service }}
{{- end -}}

{{/*
Define top-level labels for Alert Manager
*/}}
{{- define "prometheus.alertmanager.labels" -}}
{{ include "prometheus.alertmanager.matchLabels" . }}
{{ include "prometheus.common.metaLabels" . }}
{{- end -}}

{{/*
Define selector labels for Alert Manager
*/}}
{{- define "prometheus.alertmanager.matchLabels" -}}
component: {{ .Values.prometheus.alertmanager.name | quote }}
{{ include "prometheus.common.matchLabels" . }}
{{- end -}}

{{/*
Define top-level labels for Node Exporter
*/}}
{{- define "prometheus.nodeExporter.labels" -}}
{{ include "prometheus.nodeExporter.matchLabels" . }}
{{ include "prometheus.common.metaLabels" . }}
{{- end -}}

{{/*
Define selector labels for Node Exporter
*/}}
{{- define "prometheus.nodeExporter.matchLabels" -}}
component: {{ .Values.prometheus.nodeExporter.name | quote }}
{{ include "prometheus.common.matchLabels" . }}
{{- end -}}

{{/*
Define top-level labels for Push Gateway
*/}}
{{- define "prometheus.pushgateway.labels" -}}
{{ include "prometheus.pushgateway.matchLabels" . }}
{{ include "prometheus.common.metaLabels" . }}
{{- end -}}

{{/*
Define selector labels for Push Gateway
*/}}
{{- define "prometheus.pushgateway.matchLabels" -}}
component: {{ .Values.prometheus.pushgateway.name | quote }}
{{ include "prometheus.common.matchLabels" . }}
{{- end -}}

{{/*
Define top-level labels for Server
*/}}
{{- define "prometheus.server.labels" -}}
{{ include "prometheus.server.matchLabels" . }}
{{ include "prometheus.common.metaLabels" . }}
{{- end -}}

{{/*
Define selector labels for Server
*/}}
{{- define "prometheus.server.matchLabels" -}}
component: {{ .Values.prometheus.server.name | quote }}
{{ include "prometheus.common.matchLabels" . }}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "prometheus.fullname" -}}
{{- if .Values.prometheus.fullnameOverride -}}
{{- .Values.prometheus.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default "prometheus" .Values.prometheus.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create a fully qualified alertmanager name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}

{{- define "prometheus.alertmanager.fullname" -}}
{{- if .Values.prometheus.alertmanager.fullnameOverride -}}
{{- .Values.prometheus.alertmanager.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default "prometheus" .Values.prometheus.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- printf "%s-%s" .Release.Name .Values.prometheus.alertmanager.name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.prometheus.alertmanager.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}


{{/*
Create a fully qualified node-exporter name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "prometheus.nodeExporter.fullname" -}}
{{- if .Values.prometheus.nodeExporter.fullnameOverride -}}
{{- .Values.prometheus.nodeExporter.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default "prometheus" .Values.prometheus.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- printf "%s-%s" .Release.Name .Values.prometheus.nodeExporter.name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.prometheus.nodeExporter.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create a fully qualified Prometheus server name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "prometheus.server.fullname" -}}
{{- if .Values.prometheus.server.fullnameOverride -}}
{{- .Values.prometheus.server.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default "prometheus" .Values.prometheus.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- printf "%s-%s" .Release.Name .Values.prometheus.server.name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.prometheus.server.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create a fully qualified pushgateway name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "prometheus.pushgateway.fullname" -}}
{{- if .Values.prometheus.pushgateway.fullnameOverride -}}
{{- .Values.prometheus.pushgateway.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default "prometheus" .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- printf "%s-%s" .Release.Name .Values.prometheus.pushgateway.name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.prometheus.pushgateway.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use for the alertmanager component
*/}}
{{- define "prometheus.serviceAccountName.alertmanager" -}}
{{- if .Values.prometheus.serviceAccounts.alertmanager.create -}}
    {{ default (include "prometheus.alertmanager.fullname" .) .Values.prometheus.serviceAccounts.alertmanager.name }}
{{- else -}}
    {{ default "default" .Values.prometheus.serviceAccounts.alertmanager.name }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use for the nodeExporter component
*/}}
{{- define "prometheus.serviceAccountName.nodeExporter" -}}
{{- if .Values.prometheus.serviceAccounts.nodeExporter.create -}}
    {{ default (include "prometheus.nodeExporter.fullname" .) .Values.prometheus.serviceAccounts.nodeExporter.name }}
{{- else -}}
    {{ default "default" .Values.prometheus.serviceAccounts.nodeExporter.name }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use for the pushgateway component
*/}}
{{- define "prometheus.serviceAccountName.pushgateway" -}}
{{- if .Values.prometheus.serviceAccounts.pushgateway.create -}}
    {{ default (include "prometheus.pushgateway.fullname" .) .Values.prometheus.serviceAccounts.pushgateway.name }}
{{- else -}}
    {{ default "default" .Values.prometheus.serviceAccounts.pushgateway.name }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use for the server component
*/}}
{{- define "prometheus.serviceAccountName.server" -}}
{{- if .Values.prometheus.serviceAccounts.server.create -}}
    {{ default (include "prometheus.server.fullname" .) .Values.prometheus.serviceAccounts.server.name }}
{{- else -}}
    {{ default "default" .Values.prometheus.serviceAccounts.server.name }}
{{- end -}}
{{- end -}}

{{/*
==============================================================
Begin Grafana templates
==============================================================
*/}}
{{/*
Expand the name of the chart.
*/}}
{{- define "grafana.name" -}}
{{- "grafana" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "grafana.fullname" -}}
{{- if .Values.grafana.fullnameOverride -}}
{{- .Values.grafana.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default "grafana" .Values.grafana.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account
*/}}
{{- define "grafana.serviceAccountName" -}}
{{- if .Values.grafana.serviceAccount.create -}}
    {{ default (include "grafana.fullname" .) .Values.grafana.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.grafana.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
==============================================================
Begin Kubecost 2.0 templates
==============================================================
*/}}

{{- define "aggregator.containerTemplate" }}
- name: aggregator
{{- if .Values.kubecostAggregator.containerSecurityContext }}
  securityContext:
    {{- toYaml .Values.kubecostAggregator.containerSecurityContext | nindent 4 }}
{{- else if .Values.global.containerSecurityContext }}
  securityContext:
    {{- toYaml .Values.global.containerSecurityContext | nindent 4 }}
{{- end }}
  {{- if .Values.kubecostModel }}
  {{- if .Values.kubecostAggregator.fullImageName }}
  image: {{ .Values.kubecostAggregator.fullImageName }}
  {{- else if .Values.imageVersion }}
  image: {{ .Values.kubecostModel.image }}:{{ .Values.imageVersion }}
  {{- else if eq "development" .Chart.AppVersion }}
  image: gcr.io/kubecost1/cost-model-nightly:latest
  {{- else }}
  image: {{ .Values.kubecostModel.image }}:prod-{{ $.Chart.AppVersion }}
  {{- end }}
  {{- else }}
  image: gcr.io/kubecost1/cost-model:prod-{{ $.Chart.AppVersion }}
  {{- end }}
  {{- if .Values.kubecostAggregator.readinessProbe.enabled }}
  readinessProbe:
    httpGet:
      path: /healthz
      port: 9004
    initialDelaySeconds: {{ .Values.kubecostAggregator.readinessProbe.initialDelaySeconds }}
    periodSeconds: {{ .Values.kubecostAggregator.readinessProbe.periodSeconds }}
    failureThreshold: {{ .Values.kubecostAggregator.readinessProbe.failureThreshold }}
  {{- end }}
  imagePullPolicy: Always
  args: ["waterfowl"]
  ports:
    - name: tcp-api
      containerPort: 9004
      protocol: TCP
  {{- with.Values.kubecostAggregator.extraPorts }}
    {{- toYaml . | nindent 4 }}
  {{- end }}
  resources:
    {{- toYaml .Values.kubecostAggregator.resources | nindent 4 }}
  volumeMounts:
    - name: persistent-configs
      mountPath: /var/configs
    {{- if .Values.kubecostModel.federatedStorageConfigSecret }}
    - name: federated-storage-config
      mountPath: /var/configs/etl
      readOnly: true
    {{- else if eq (include "aggregator.deployMethod" .) "statefulset" }}
    {{- fail "When in StatefulSet mode, Aggregator requires that kubecostModel.federatedStorageConfigSecret be set." }}
    {{- end }}
    {{- if and .Values.persistentVolume.dbPVEnabled (eq (include "aggregator.deployMethod" .) "singlepod") }}
    - name: persistent-db
      mountPath: /var/db
      # aggregator should only need read access to ETL data
      readOnly: true
    {{- end }}
    {{- if eq (include "aggregator.deployMethod" .) "statefulset" }}
    - name: aggregator-db-storage
      mountPath: /var/configs/waterfowl/duckdb
    - name: aggregator-staging
      # Aggregator uses /var/configs/waterfowl as a "staging" directory for
      # things like intermediate-state files pre-ingestion. In order to avoid a
      # permission problem similar to
      # https://github.com/kubernetes/kubernetes/issues/81676, we create an
      # emptyDir at this path.
      #
      # This hasn't been observed as a problem in cost-analyzer, likely because
      # of the init container that gives everything under /var/configs 777.
      mountPath: /var/configs/waterfowl
    {{- end }}
    {{- if and ((.Values.kubecostProductConfigs).productKey).enabled ((.Values.kubecostProductConfigs).productKey).secretname (eq (include "aggregator.deployMethod" .) "statefulset") }}
    - name: productkey-secret
      mountPath: /var/configs/productkey
    {{- end }}
    {{- if .Values.saml }}
    {{- if .Values.saml.enabled }}
    {{- if .Values.saml.secretName }}
    - name: secret-volume
      mountPath: /var/configs/secret-volume
    {{- end }}
    {{- if .Values.saml.encryptionCertSecret }}
    - name: saml-encryption-cert
      mountPath: /var/configs/saml-encryption-cert
    {{- end }}
    {{- if .Values.saml.decryptionKeySecret }}
    - name: saml-decryption-key
      mountPath: /var/configs/saml-decryption-key
    {{- end }}
    {{- if .Values.saml.metadataSecretName }}
    - name: metadata-secret-volume
      mountPath: /var/configs/metadata-secret-volume
    {{- end }}
    - name: saml-auth-secret
      mountPath: /var/configs/saml-auth-secret
    {{- if .Values.saml.rbac.enabled }}
    - name: saml-roles
      mountPath: /var/configs/saml
    {{- end }}
    {{- end }}
    {{- end }}
    {{- if .Values.oidc }}
    {{- if .Values.oidc.enabled }}
    - name: oidc-config
      mountPath: /var/configs/oidc
    {{- if or .Values.oidc.existingCustomSecret.name .Values.oidc.secretName }}
    - name: oidc-client-secret
      mountPath: /var/configs/oidc-client-secret
    {{- end }}
    {{- end }}
    {{- end }}
  env:
    {{- if and (.Values.prometheus.server.global.external_labels.cluster_id) (not .Values.prometheus.server.clusterIDConfigmap) }}
    - name: CLUSTER_ID
      value: {{ .Values.prometheus.server.global.external_labels.cluster_id }}
    {{- end }}
    {{- if .Values.prometheus.server.clusterIDConfigmap }}
    - name: CLUSTER_ID
      valueFrom:
        configMapKeyRef:
          name: {{ .Values.prometheus.server.clusterIDConfigmap }}
          key: CLUSTER_ID
    {{- end }}
    {{- if and ((.Values.kubecostProductConfigs).productKey).mountPath (eq (include "aggregator.deployMethod" .) "statefulset") }}
    - name: PRODUCT_KEY_MOUNT_PATH
      value: {{ .Values.kubecostProductConfigs.productKey.mountPath }}
    {{- end }}
    {{- if (gt (int .Values.kubecostAggregator.numDBCopyPartitions) 0) }}
    - name: NUM_DB_COPY_CHUNKS
      value: {{ .Values.kubecostAggregator.numDBCopyPartitions | quote }}
    {{- end }}
    {{- if .Values.kubecostAggregator.jaeger.enabled }}
    - name: TRACING_URL
      value: "http://localhost:14268/api/traces"
    {{- end }}
    - name: CONFIG_PATH
      value: /var/configs/
    {{- if and .Values.persistentVolume.dbPVEnabled (eq (include "aggregator.deployMethod" .) "singlepod") }}
    - name: ETL_PATH_PREFIX
      value: "/var/db"
    {{- end }}
    - name: ETL_ENABLED
      value: "false" # this container should never run KC's concept of "ETL"
    - name: CLOUD_PROVIDER_API_KEY
      value: "AIzaSyDXQPG_MHUEy9neR7stolq6l0ujXmjJlvk" # The GCP Pricing API key.This GCP api key is expected to be here and is limited to accessing google's billing API.'
    {{- if .Values.systemProxy.enabled }}
    - name: HTTP_PROXY
      value: {{ .Values.systemProxy.httpProxyUrl }}
    - name: http_proxy
      value: {{ .Values.systemProxy.httpProxyUrl }}
    - name: HTTPS_PROXY
      value:  {{ .Values.systemProxy.httpsProxyUrl }}
    - name: https_proxy
      value:  {{ .Values.systemProxy.httpsProxyUrl }}
    - name: NO_PROXY
      value:  {{ .Values.systemProxy.noProxy }}
    - name: no_proxy
      value:  {{ .Values.systemProxy.noProxy }}
    {{- end }}
    {{- if ((.Values.kubecostProductConfigs).carbonEstimates) }}
    - name: CARBON_ESTIMATES_ENABLED
      value: "true"
    {{- end }}
    - name: CUSTOM_COST_ENABLED
      value: {{ .Values.kubecostModel.plugins.enabled | quote }}
    {{- if .Values.kubecostAggregator.extraEnv -}}
    {{- toYaml .Values.kubecostAggregator.extraEnv | nindent 4 }}
    {{- end }}
    {{- if eq (include "aggregator.deployMethod" .) "statefulset" }}
    # If this isn't set, we pretty much have to be in a read only state,
    # initialization will probably fail otherwise.
    - name: ETL_BUCKET_CONFIG
      {{- if not .Values.kubecostModel.federatedStorageConfigSecret }}
      value: /var/configs/etl/object-store.yaml
      {{- else }}
      value: /var/configs/etl/federated-store.yaml
    - name: FEDERATED_STORE_CONFIG
      value: /var/configs/etl/federated-store.yaml
    - name: FEDERATED_PRIMARY_CLUSTER # this ensures the ingester runs assuming federated primary paths in the bucket
      value: "true"
    - name: FEDERATED_CLUSTER # this ensures the ingester runs assuming federated primary paths in the bucket
      value: "true"
      {{- end }}
    {{- end }}

    {{- range $key, $value := .Values.kubecostAggregator.env }}
    - name: {{ $key | quote }}
      value: {{ $value | quote }}
    {{- end }}
    - name: KUBECOST_NAMESPACE
      value: {{ .Release.Namespace }}
    {{- if .Values.oidc.enabled }}
    - name: OIDC_ENABLED
      value: "true"
    - name: OIDC_SKIP_ONLINE_VALIDATION
      value: {{ (quote .Values.oidc.skipOnlineTokenValidation) | default (quote false) }}
    {{- end}}
    {{- if .Values.kubecostAggregator }}
    {{- if .Values.kubecostAggregator.collections }}
    {{- if (((.Values.kubecostAggregator).collections).cache) }}
    - name: COLLECTIONS_MEMORY_CACHE_ENABLED
      value: {{ (quote .Values.kubecostAggregator.collections.cache.enabled) | default (quote true) }}
    {{- end }}
    {{- end }}
    {{- end }}
    {{- if .Values.saml }}
    {{- if .Values.saml.enabled }}
    - name: SAML_ENABLED
      value: "true"
    - name: IDP_URL
      value: {{ .Values.saml.idpMetadataURL }}
    - name: SP_HOST
      value: {{ .Values.saml.appRootURL }}
    {{- if .Values.saml.audienceURI }}
    - name: AUDIENCE_URI
      value: {{ .Values.saml.audienceURI }}
    {{- end }}
    {{- if .Values.saml.isGLUUProvider }}
    - name: GLUU_SAML_PROVIDER
      value: {{ (quote .Values.saml.isGLUUProvider) }}
    {{- end }}
    {{- if .Values.saml.nameIDFormat }}
    - name: NAME_ID_FORMAT
      value: {{ .Values.saml.nameIDFormat }}
    {{- end}}
    {{- if .Values.saml.authTimeout }}
    - name: AUTH_TOKEN_TIMEOUT
      value: {{ (quote .Values.saml.authTimeout) }}
    {{- end}}
    {{- if .Values.saml.redirectURL }}
    - name: LOGOUT_REDIRECT_URL
      value: {{ .Values.saml.redirectURL }}
    {{- end}}
    {{- if .Values.saml.rbac.enabled }}
    - name: SAML_RBAC_ENABLED
      value: "true"
    {{- end }}
    {{- if and .Values.saml.encryptionCertSecret .Values.saml.decryptionKeySecret }}
    - name: SAML_RESPONSE_ENCRYPTED
      value: "true"
    {{- end}}
    {{- end }}
    {{- end }}
{{- end }}


{{- define "aggregator.jaeger.sidecarContainerTemplate" }}
- name: embedded-jaeger
  env:
  - name: SPAN_STORAGE_TYPE
    value: badger
  - name: BADGER_EPHEMERAL
    value: "true"
  - name: BADGER_DIRECTORY_VALUE
    value: /tmp/badger/data
  - name: BADGER_DIRECTORY_KEY
    value: /tmp/badger/key
  securityContext:
    {{- toYaml .Values.kubecostAggregator.jaeger.containerSecurityContext | nindent 4 }}
  image: {{ .Values.kubecostAggregator.jaeger.image }}:{{ .Values.kubecostAggregator.jaeger.imageVersion }}
{{- end }}


{{- define "aggregator.cloudCost.containerTemplate" }}
- name: cloud-cost
  {{- if .Values.kubecostModel }}
  {{- if .Values.kubecostAggregator.fullImageName }}
  image: {{ .Values.kubecostAggregator.fullImageName }}
  {{- else if .Values.kubecostModel.fullImageName }}
  image: {{ .Values.kubecostModel.fullImageName }}
  {{- else if .Values.imageVersion }}
  image: {{ .Values.kubecostModel.image }}:{{ .Values.imageVersion }}
  {{- else if eq "development" .Chart.AppVersion }}
  image: gcr.io/kubecost1/cost-model-nightly:latest
  {{- else }}
  image: {{ .Values.kubecostModel.image }}:prod-{{ $.Chart.AppVersion }}
  {{ end }}
  {{- else }}
  image: gcr.io/kubecost1/cost-model:prod-{{ $.Chart.AppVersion }}
  {{ end }}
  {{- if .Values.kubecostAggregator.cloudCost.readinessProbe.enabled }}
  readinessProbe:
    httpGet:
      path: /healthz
      port: 9005
    initialDelaySeconds: {{ .Values.kubecostAggregator.cloudCost.readinessProbe.initialDelaySeconds }}
    periodSeconds: {{ .Values.kubecostAggregator.cloudCost.readinessProbe.periodSeconds }}
    failureThreshold: {{ .Values.kubecostAggregator.cloudCost.readinessProbe.failureThreshold }}
  {{- end }}
  imagePullPolicy: Always
  args: ["cloud-cost"]
  ports:
    - name: tcp-api
      containerPort: 9005
      protocol: TCP
  resources:
    {{- toYaml .Values.kubecostAggregator.cloudCost.resources | nindent 4 }}
  securityContext:
    {{- if .Values.global.containerSecurityContext }}
    {{- toYaml .Values.global.containerSecurityContext | nindent 4 }}
    {{- end }}
  volumeMounts:
    - name: persistent-configs
      mountPath: /var/configs
  {{- if .Values.kubecostModel.federatedStorageConfigSecret }}
    - name: federated-storage-config
      mountPath: /var/configs/etl/federated
      readOnly: true
  {{- else if .Values.kubecostModel.etlBucketConfigSecret }}
    - name: etl-bucket-config
      mountPath: /var/configs/etl
      readOnly: true
  {{- end }}
  {{- if or (.Values.kubecostProductConfigs).cloudIntegrationSecret (.Values.kubecostProductConfigs).cloudIntegrationJSON ((.Values.kubecostProductConfigs).athenaBucketName) }}
    - name: cloud-integration
      mountPath: /var/configs/cloud-integration
  {{- end }}
    {{- if .Values.kubecostModel.plugins.enabled }}
    - mountPath: {{ .Values.kubecostModel.plugins.folder }}
      name: plugins-dir
      readOnly: false
    - name: tmp
      mountPath: /tmp
    {{- range $key := .Values.kubecostModel.plugins.enabledPlugins }}
    - mountPath: {{ $.Values.kubecostModel.plugins.folder }}/config
      name: plugins-config
      readOnly: true
    {{- end }}
    {{- end }}
  env:
    - name: CONFIG_PATH
      value: /var/configs/
    {{- if .Values.kubecostModel.etlBucketConfigSecret }}
    - name: ETL_BUCKET_CONFIG
      value: /var/configs/etl/object-store.yaml
    {{- end}}
    {{- if .Values.kubecostModel.federatedStorageConfigSecret }}
    - name: FEDERATED_STORE_CONFIG
      value: /var/configs/etl/federated/federated-store.yaml
    - name: FEDERATED_CLUSTER
      value: "true"
    {{- end}}
    - name: CLOUD_COST_REFRESH_RATE_HOURS
      value: {{ .Values.kubecostAggregator.cloudCost.refreshRateHours | default 6 | quote }}
    - name: CLOUD_COST_QUERY_WINDOW_DAYS
      value: {{ .Values.kubecostAggregator.cloudCost.queryWindowDays | default 7 | quote }}
    - name: CLOUD_COST_RUN_WINDOW_DAYS
      value: {{ .Values.kubecostAggregator.cloudCost.runWindowDays | default 3 | quote }}
    - name: CUSTOM_COST_ENABLED
      value: {{ .Values.kubecostModel.plugins.enabled | quote }}
    {{- with .Values.kubecostModel.cloudCost }}
    {{- with .labelList }}
    - name: CLOUD_COST_IS_INCLUDE_LIST
      value: {{ (quote .IsIncludeList) | default (quote false) }}
    - name: CLOUD_COST_LABEL_LIST
      value: {{ (quote .labels) }}
    {{- end }}
    - name: CLOUD_COST_TOP_N
      value: {{ (quote .topNItems) | default (quote 1000) }}
    {{- end }}
    {{- range $key, $value := .Values.kubecostAggregator.cloudCost.env }}
    - name: {{ $key | quote }}
      value: {{ $value | quote }}
    {{- end }}
    {{- if .Values.systemProxy.enabled }}
    - name: HTTP_PROXY
      value: {{ .Values.systemProxy.httpProxyUrl }}
    - name: http_proxy
      value: {{ .Values.systemProxy.httpProxyUrl }}
    - name: HTTPS_PROXY
      value: {{ .Values.systemProxy.httpsProxyUrl }}
    - name: https_proxy
      value: {{ .Values.systemProxy.httpsProxyUrl }}
    - name: NO_PROXY
      value: {{ .Values.systemProxy.noProxy }}
    - name: no_proxy
      value: {{ .Values.systemProxy.noProxy }}
    {{- end }}
{{- end }}

{{/*
SSO enabled flag for nginx configmap
*/}}
{{- define "ssoEnabled" -}}
  {{- if or (.Values.saml).enabled (.Values.oidc).enabled -}}
    {{- printf "true" -}}
  {{- else -}}
    {{- printf "false" -}}
  {{- end -}}
{{- end -}}

{{/*
Backups configured flag for nginx configmap
*/}}
{{- define "dataBackupConfigured" -}}
  {{- if or (.Values.kubecostModel).etlBucketConfigSecret (.Values.kubecostModel).federatedStorageConfigSecret -}}
    {{- printf "true" -}}
  {{- else -}}
    {{- printf "false" -}}
  {{- end -}}
{{- end -}}

{{/*
costEventsAuditEnabled flag for nginx configmap
*/}}
{{- define "costEventsAuditEnabled" -}}
  {{- if or (.Values.costEventsAudit).enabled -}}
    {{- printf "true" -}}
  {{- else -}}
    {{- printf "false" -}}
  {{- end -}}
{{- end -}}

{{- define "cost-analyzer.grafanaEnabled" -}}
  {{- if and (.Values.global.grafana.enabled) (not .Values.federatedETL.agentOnly)  -}}
    {{- printf "true" -}}
  {{- else -}}
    {{- printf "false" -}}
  {{- end -}}
{{- end -}}

{{- define "gcpCloudIntegrationJSON" }}
Kubecost 2.x requires a change to the method that cloud-provider billing integrations are configured.
Please use this output to create a cloud-integration.json config. See:
<https://docs.kubecost.com/install-and-configure/install/cloud-integration#adding-a-cloud-integration>
for more information

  {
    "gcp":
      {
        [
          {
              "bigQueryBillingDataDataset": "{{ .Values.kubecostProductConfigs.bigQueryBillingDataDataset }}",
              "bigQueryBillingDataProject": "{{ .Values.kubecostProductConfigs.bigQueryBillingDataProject }}",
              "bigQueryBillingDataTable": "{{ .Values.kubecostProductConfigs.bigQueryBillingDataTable }}",
              "projectID": "{{ .Values.kubecostProductConfigs.projectID }}"
          }
        ]
      }
  }
{{- end }}

{{- define "gcpCloudIntegrationCheck" }}
{{- if ((.Values.kubecostProductConfigs).bigQueryBillingDataDataset) }}
{{- fail (include "gcpCloudIntegrationJSON" .) }}
{{- end }}
{{- end }}


{{- define "azureCloudIntegrationJSON" }}

Kubecost 2.x requires a change to the method that cloud-provider billing integrations are configured.
Please use this output to create a cloud-integration.json config. See:
<https://docs.kubecost.com/install-and-configure/install/cloud-integration#adding-a-cloud-integration>
for more information
  {
    "azure":
      [
        {
            "azureStorageContainer": "{{ .Values.kubecostProductConfigs.azureStorageContainer }}",
            "azureSubscriptionID": "{{ .Values.kubecostProductConfigs.azureSubscriptionID }}",
            "azureStorageAccount": "{{ .Values.kubecostProductConfigs.azureStorageAccount }}",
            "azureStorageAccessKey": "{{ .Values.kubecostProductConfigs.azureStorageKey }}",
            "azureContainerPath": "{{ .Values.kubecostProductConfigs.azureContainerPath }}",
            "azureCloud": "{{ .Values.kubecostProductConfigs.azureCloud }}"
        }
      ]
  }
{{- end }}

{{- define "azureCloudIntegrationCheck" }}
{{- if ((.Values.kubecostProductConfigs).azureStorageContainer) }}
{{- fail (include "azureCloudIntegrationJSON" .) }}
{{- end }}
{{- end }}

{{- define "clusterControllerEnabled" }}
{{- if (.Values.clusterController).enabled }}
{{- printf "true" -}}
{{- else -}}
{{- printf "false" -}}
{{- end -}}
{{- end -}}

{{- define "pluginsEnabled" }}
{{- if ((.Values.kubecostModel.plugins).install).enabled}}
{{- printf "true" -}}
{{- else -}}
{{- printf "false" -}}
{{- end -}}
{{- end -}}