{{- /*
Return the full name of the chart resource
*/ -}}
{{- define "otel-collector.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
