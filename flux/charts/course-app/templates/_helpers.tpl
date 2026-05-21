{{/*
Повне ім'я ресурсу (на основі імені release).
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
Selector лейбли (immutable — не міняти між релізами).
*/}}
{{- define "course-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "course-app.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Ім'я інстанса Dragonfly. Operator створює Service з таким самим ім'ям.
*/}}
{{- define "course-app.dragonflyName" -}}
{{- printf "%s-dragonfly" (include "course-app.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Redis URL -> Service Dragonfly у тому ж namespace.
*/}}
{{- define "course-app.redisUrl" -}}
redis://{{ include "course-app.dragonflyName" . }}:6379/0
{{- end }}
