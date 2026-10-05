{{/*
Helpers
*/}}

{{ define "scribe-lite.name" -}}
{{ default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{ end -}}

{{ define "scribe-lite.fullname" -}}
{{ if .Values.fullnameOverride -}}
{{ .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{ else -}}
{{ $name := include "scribe-lite.name" . -}}
{{ printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{ end -}}
{{ end -}}

{{ define "scribe-lite.labels" }}
app.kubernetes.io/name: {{ include "scribe-lite.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{ end }}

{{ define "scribe-lite.selectorLabels" }}
app.kubernetes.io/name: {{ include "scribe-lite.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{ end }}

{{ define "scribe-lite.serviceAccountName" -}}
{{ if .Values.serviceAccount.create -}}
{{ default (include "scribe-lite.fullname" .) .Values.serviceAccount.name -}}
{{ else -}}
{{ default "default" .Values.serviceAccount.name -}}
{{ end -}}
{{ end -}}

{{ define "scribe-lite.configmapName" -}}
{{ include "scribe-lite.fullname" . }}-config
{{ end -}}

{{ define "scribe-lite.secretName" -}}
{{ if .Values.scribe.existingSecret -}}
{{ .Values.scribe.existingSecret }}
{{ else -}}
{{ include "scribe-lite.fullname" . }}-secret
{{ end -}}
{{ end }}
