{{- define "dbpMoodle.stageBackupEnabled" -}}
{{- if and (or (eq .Values.global.stage "prod") (eq .Values.global.name "infra")) ( .Values.backup.enabled ) -}}
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

{{- define "moodle_hpa.deployment_name_ref" -}}
{{- default "moodle" .Values.moodle_hpa.deployment_name_ref }}
{{- end -}}

{{- define "dbpMoodle.secrets.moodle_password" -}}
{{- default (randAlphaNum 16) .Values.dbpMoodle.secrets.moodle_password }}
{{- end -}}

{{- define "dbpMoodle.secrets.postgres_password" -}}
{{- default (randAlphaNum 16) .Values.dbpMoodle.secrets.postgres_password }}
{{- end -}}

{{- define "dbpMoodle.secrets.mariadb_password" -}}
{{- default (randAlphaNum 16) .Values.dbpMoodle.secrets.mariadb_password }}
{{- end -}}

{{- define "dbpMoodle.secrets.mariadb_root_password" -}}
{{- default (randAlphaNum 16) .Values.dbpMoodle.secrets.mariadb_root_password }}
{{- end -}}

{{- define "dbpMoodle.secrets.redis_password" -}}
{{- default (randAlphaNum 16) .Values.dbpMoodle.redis.password }}
{{- end -}}

{{- define "dbpMoodle.secrets.etherpad_postgresql_password" -}}
{{- default (randAlphaNum 16) .Values.dbpMoodle.secrets.etherpad_postgresql_password }}
{{- end -}}

{{- define "dbpMoodle.secrets.etherpad_api_key" -}}
{{- default "moodle" .Values.dbpMoodle.secrets.etherpad_api_key }}
{{- end -}}