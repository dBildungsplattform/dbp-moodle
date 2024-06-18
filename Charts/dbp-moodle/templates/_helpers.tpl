{{- define "dbpMoodle.stageBackupEnabled" -}}
{{- if or (eq .Values.global.stage "prod") (eq .Values.global.name "infra") -}}
true
{{- else -}}
false
{{- end -}}
{{- end -}}