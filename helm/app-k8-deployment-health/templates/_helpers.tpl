{{- define "app-k8-deployment-health.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "app-k8-deployment-health.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- include "app-k8-deployment-health.name" . }}
{{- end }}
{{- end }}

{{- define "app-k8-deployment-health.labels" -}}
app.kubernetes.io/name: {{ include "app-k8-deployment-health.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
