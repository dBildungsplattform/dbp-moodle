{{- define "dbpMoodle.stageBackupEnabled" -}}
{{- if or (eq .Values.global.stage "prod") (eq .Values.global.name "infra") -}}
true
{{- else -}}
false
{{- end -}}
{{- end -}}

{{- define "dbpMoodle.moodlePvc.name" -}}
{{- if .Values.external_pvc.enabled }}
"{{- .Values.external_pvc.name -}}"
{{- else if .Values.moodle.persistence.enabled }}
"{{- .Release.Name }}-moodle"
{{- else }}
{{- printf "Warning: Neither external_pvc nor moodle.persistence is enabled, using default value 'moodle-moodle' which will probably fail." }}
"moodle-moodle"
{{- end -}}
{{- end -}}

{{- define "dbpMoodle.secret.defaulting" -}}
{{- if . -}}
{{ . }}
{{- else -}}
{{ randAlphaNum 16 | quote }}
{{- end -}}
{{- end -}}