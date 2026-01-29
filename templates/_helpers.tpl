{{/*
Expand the name of the chart.
*/}}
{{- define "n8n-deployment.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "n8n-deployment.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "n8n-deployment.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "n8n-deployment.labels" -}}
helm.sh/chart: {{ include "n8n-deployment.chart" . }}
{{ include "n8n-deployment.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "n8n-deployment.selectorLabels" -}}
app.kubernetes.io/name: {{ include "n8n-deployment.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create a default fully qualified app name for SeleniumBase.
*/}}
{{- define "seleniumbase.fullname" -}}
{{- if .Values.seleniumbase.fullnameOverride }}
{{- .Values.seleniumbase.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-seleniumbase" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use for SeleniumBase
*/}}
{{- define "seleniumbase.serviceAccountName" -}}
{{- if .Values.seleniumbase.serviceAccount.create }}
{{- default (include "seleniumbase.fullname" .) .Values.seleniumbase.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.seleniumbase.serviceAccount.name }}
{{- end }}
{{- end }}
