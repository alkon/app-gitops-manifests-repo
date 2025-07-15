{{- /*
Return the short name of the chart
*/ -}}
{{- define "otel-collector.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- /*
Return the full name (release + chart name)
*/ -}}
{{- define "otel-collector.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name (include "otel-collector.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end -}}
