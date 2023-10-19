{{/* vim: set filetype=mustache: */}}

{{- define "kubecost.test.annotations" -}}
helm.sh/hook: test
{{- end -}}

{{- define "kyverno.test.image" -}}
{{- template "kyverno.image" (dict "image" .Values.test.image "defaultTag" "latest") -}}
{{- end -}}

{{- define "kyverno.test.imagePullPolicy" -}}
{{- default .Values.admissionController.container.image.pullPolicy .Values.test.image.pullPolicy -}}
{{- end -}}