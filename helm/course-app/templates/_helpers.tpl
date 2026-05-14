{{/*
Повне ім'я ресурсу
*/}}
{{- define "course-app.fullname" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Загальні лейбли
*/}}
{{- define "course-app.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{ include "course-app.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector лейбли
*/}}
{{- define "course-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "course-app.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Redis URL — автоматично формується з імені release
Bitnami Redis standalone master має Service: <release>-redis-master
*/}}
{{- define "course-app.redisUrl" -}}
redis://{{ .Release.Name }}-redis-master:6379/0
{{- end }}

