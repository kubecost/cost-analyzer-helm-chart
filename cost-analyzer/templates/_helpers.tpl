{{/* vim: set filetype=mustache: */}}

{{/*
Set important variables before starting main templates
*/}}
{{- define "aggregator.deployMethod" -}}
  {{- if (not .Values.kubecostAggregator) }}
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

{{/* Cloud Cost inherits its deploy method from Aggregator. Either
kubecostModel.cloudCost.enabled OR kubecostAggregator.cloudCost.enabled will
enable it. */}}
{{- define "cloudCost.deployMethod" -}}
  {{ if not (or .Values.kubecostModel.cloudCost.enabled .Values.kubecostAggregator.cloudCost.enabled) }}
    {{- printf "disabled" }}
  {{ else if eq (include "aggregator.deployMethod" .) "none" }}
    {{- printf "disabled" }}
  {{- else if eq (include "aggregator.deployMethod" .) "statefulset" }}
    {{- printf "deployment" }}
  {{- else if eq (include "aggregator.deployMethod" .) "singlepod" }}
    {{- printf "singlepod" }}
  {{- else }}
    {{ fail "Unable to set cloudCost.deployMethod" }}
  {{- end }}
{{- end }}


{{/*
Kubecost 2.0 preconditions
*/}}
{{ if .Values.federatedETL }}
  {{ if .Values.federatedETL.primaryCluster }}
    {{ fail "In Kubecost 2.0, there is no such thing as a federated primary. If you are a Federated ETL user, this setting has been removed. Make sure you have kubecostAggregator.deployMethod set to 'statefulset' and federatedETL.federatedCluster set to 'true'." }}
  {{ end }}
{{ end }}
{{ if not .Values.kubecostModel.etlFileStoreEnabled }}
  {{ fail "Kubecost 2.0 does not support running fully in-memory. Some file system must be available to store cost data." }}
{{ end }}


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
{{- printf "%s-%s" .Release.Name "cost-analyzer" | trunc 63 | trimSuffix "-" -}}
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
{{- end -}}

{{/*
Create the selector labels.
*/}}
{{- define "cost-analyzer.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cost-analyzer.name" . }}
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
{{- if eq (include "cloudCost.deployMethod" .) "deployment" }}
app.kubernetes.io/name: {{ include "cloudCost.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app: {{ include "cloudCost.name" . }}
{{- else if eq (include "cloudCost.deployMethod" .) "singlepod" }}
{{- include "cost-analyzer.selectorLabels" . }}
{{- end }}
{{- end }}

{{- define "etlUtils.selectorLabels" -}}
app.kubernetes.io/name: {{ include "etlUtils.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app: {{ include "etlUtils.name" . }}
{{- end -}}

{{/*
Return the appropriate apiVersion for daemonset.
*/}}
{{- define "cost-analyzer.daemonset.apiVersion" -}}
{{- if semverCompare "<1.9-0" .Capabilities.KubeVersion.GitVersion -}}
{{- print "extensions/v1beta1" -}}
{{- else if semverCompare "^1.9-0" .Capabilities.KubeVersion.GitVersion -}}
{{- print "apps/v1" -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for priorityClass.
*/}}
{{- define "cost-analyzer.priorityClass.apiVersion" -}}
{{- if semverCompare "<1.14-0" .Capabilities.KubeVersion.GitVersion -}}
{{- print "scheduling.k8s.io/v1beta1" -}}
{{- else if semverCompare "^1.14-0" .Capabilities.KubeVersion.GitVersion -}}
{{- print "scheduling.k8s.io/v1" -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for networkpolicy.
*/}}
{{- define "cost-analyzer.networkPolicy.apiVersion" -}}
{{- if semverCompare ">=1.4-0, <1.7-0" .Capabilities.KubeVersion.GitVersion -}}
{{- print "extensions/v1beta1" -}}
{{- else if semverCompare "^1.7-0" .Capabilities.KubeVersion.GitVersion -}}
{{- print "networking.k8s.io/v1" -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for podsecuritypolicy.
*/}}
{{- define "cost-analyzer.podSecurityPolicy.apiVersion" -}}
{{- if semverCompare ">=1.3-0, <1.10-0" .Capabilities.KubeVersion.GitVersion -}}
{{- print "extensions/v1beta1" -}}
{{- else if semverCompare "^1.10-0" .Capabilities.KubeVersion.GitVersion -}}
{{- print "policy/v1beta1" -}}
{{- end -}}
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
 Check KC 2.0 values requirements that may differ
*/}}
{{ if .Values.federatedETL }}
  {{ if .Values.federatedETL.primaryCluster }}
    {{ fail "In Kubecost 2.0, all federated configurations must be set up as secondary" }}
  {{ end }}
{{ end }}

{{ if .Values.kubecostModel }}
  {{ if .Values.kubecostModel.openSourceOnly }}
    {{ fail "In Kubecost 2.0, kubecostModel.openSourceOnly is not supported" }}
  {{ end }}
{{ end }}

{{/*
 Aggregator config reconciliation and common config
*/}}
{{ if eq (include "aggregator.deployMethod" .) "statefulset" }}
  {{ if .Values.kubecostAggregator }}
    {{ if (not .values.kubecostAggregator.aggregatorDbStorage) }}
      {{ fail "In Enterprise configuration, Aggregator DB storage is required" }}
    {{ end }}
  {{ end }}
{{ end }}


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
    {{- $etlBackupBucketSecret := "" }}
    {{- if .Values.kubecostModel.federatedStorageConfigSecret }}
        {{- $etlBackupBucketSecret = .Values.kubecostModel.federatedStorageConfigSecret }}
    {{- end }}
    {{- if $etlBackupBucketSecret }}
    - name: etl-bucket-config
      mountPath: /var/configs/etl
      readOnly: true
    {{- else if and .Values.persistentVolume.dbPVEnabled (eq (include "aggregator.deployMethod" .) "singlepod") }}
    - name: persistent-db
      mountPath: /var/db
      # aggregator should only need read access to ETL data
      readOnly: true
    {{- end }}
    {{- if eq (include "aggregator.deployMethod" .) "statefulset" }}
    - name: aggregator-storage
      mountPath: /var/configs/waterfowl/duckdb
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
    {{- if .Values.kubecostAggregator.extraEnv -}}
    {{- toYaml .Values.kubecostAggregator.extraEnv | nindent 4 }}
    {{- end }}
    {{- if $etlBackupBucketSecret }}
    # If this isn't set, we pretty much have to be in a read only state,
    # initialization will probably fail otherwise.
    - name: ETL_BUCKET_CONFIG
      {{- if not .Values.kubecostModel.federatedStorageConfigSecret}}
      value: /var/configs/etl/object-store.yaml
      {{- else  }}
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
{{- end }}


{{- define "aggregator.jaeger.sidecarContainerTemplate" }}
- name: embedded-jaeger
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
  volumeMounts:
  {{- if .Values.kubecostModel.federatedStorageConfigSecret }}
    - name: federated-storage-config
      mountPath: /var/configs/etl/federated
      readOnly: true
  {{- end }}
  {{- if .Values.kubecostModel.etlBucketConfigSecret }}
    - name: etl-bucket-config
      mountPath: /var/configs/etl
      readOnly: true
  {{- end }}
  {{- if .Values.kubecostProductConfigs }}
  {{- if .Values.kubecostProductConfigs.cloudIntegrationSecret }}
    - name: {{ .Values.kubecostProductConfigs.cloudIntegrationSecret }}
      mountPath: /var/configs/cloud-integration
  {{- else }}
    # In this case, the cloud-integration is expected to come from the UI or
    # from workload identity.
    - name: cloud-integration
      mountPath: /var/configs/cloud-integration
  {{- end }}
    # In this case, the cloud-integration is expected to come from the UI or
    # from workload identity.
    - name: cloud-integration
      mountPath: /var/configs/cloud-integration
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
