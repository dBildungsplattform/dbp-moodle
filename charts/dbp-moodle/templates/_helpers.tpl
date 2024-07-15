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

{{- define "dbpMoodle.pluginConfigMap.content" -}}
wunderbyte_table:local_wunderbyte_table:local/wunderbyte_table: {{- .Values.global.plugins.booking.enabled }}
certificate:tool_certificate:admin/tool/certificate:            {{- or .Values.global.plugins.certificate.enabled .Values.global.plugins.coursecertificate.enabled }}
etherpadlite:mod_etherpadlite:mod/etherpadlite:                 {{- .Values.global.plugins.etherpadlite.enabled }}
hvp:mod_hvp:mod/hvp:                                            {{- .Values.global.plugins.hvp.enabled }}
groupselect:mod_groupselect:mod/groupselect:                    {{- .Values.global.plugins.groupselect.enabled }}
jitsi:mod_jitsi:mod/jitsi:                                      {{- .Values.global.plugins.jitsi.enabled }}
pdfannotator:mod_pdfannotator:mod/pdfannotator:                 {{- .Values.global.plugins.pdfannotator.enabled }}
skype:mod_skype:mod/skype:                                      {{- .Values.global.plugins.skype.enabled }}
zoom:mod_zoom:mod/zoom:                                         {{- .Values.global.plugins.zoom.enabled }}
booking:mod_booking:mod/booking:                                {{- .Values.global.plugins.booking.enabled }}
reengagement:mod_reengagement:mod/reengagement:                 {{- .Values.global.plugins.reengagement.enabled }}
unilabel:mod_unilabel:mod/unilabel:                             {{- .Values.global.plugins.unilabel.enabled }}
geogebra:mod_geogebra:mod/geogebra:                             {{- .Values.global.plugins.geogebra.enabled }}
remuiformat:format_remuiformat:course/format/remuiformat:       {{- .Values.global.plugins.remuiformat.enabled }}
tiles:format_tiles:course/format/tiles:                         {{- .Values.global.plugins.tiles.enabled }}
topcoll:format_topcoll:course/format/topcoll:                   {{- .Values.global.plugins.topcoll.enabled }}
oidc:auth_oidc:auth/oidc:                                       {{- .Values.global.plugins.oidc.enabled }}
saml2:auth_saml2:auth/saml2:                                    {{- .Values.global.plugins.saml2.enabled }}
dash:block_dash:blocks/dash:                                    {{- .Values.global.plugins.dash.enabled }}
sharing_cart:block_sharing_cart:blocks/sharing_cart:            {{- .Values.global.plugins.sharing_cart.enabled }}
xp:block_xp:blocks/xp:                                          {{- .Values.global.plugins.xp.enabled }}
coursecertificate:mod_coursecertificate:mod/coursecertificate:  {{- .Values.global.plugins.coursecertificate.enabled }}
boost_union:theme_boost_union:theme/boost_union:                {{- .Values.global.plugins.boost_union.enabled }}
{{- end -}}
