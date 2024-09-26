{{- define "dbpMoodle.stageBackupEnabled" -}}
{{- if and (or (eq .Values.dbpMoodle.stage "prod") (eq .Values.dbpMoodle.name "infra")) ( .Values.dbpMoodle.backup.enabled ) -}}
true
{{- else -}}
false
{{- end -}}
{{- end -}}

{{- define "dbpMoodle.moodlePvc.name" -}}
{{- if .Values.dbpMoodle.external_pvc.enabled }}
{{- .Values.dbpMoodle.external_pvc.name -}}
{{- else if .Values.moodle.persistence.enabled }}
{{- .Release.Name }}-moodle
{{- else }}
{{- printf "Warning: Neither external_pvc nor moodle.persistence is enabled, using default value 'moodle-moodle' which will probably fail." }}
"moodle-moodle"
{{- end -}}
{{- end -}}

{{- define "dbpMoodle.hpa.deployment_name_ref" -}}
{{- default "moodle" .Values.dbpMoodle.hpa.deployment_name_ref }}
{{- end -}}

{{- define "moodlecronjob.job_name" -}}
{{- with (index .Values.moodlecronjob.jobs 0) -}}
{{- .name -}}
{{- end -}}
{{- end -}}

{{- define "dbpMoodle.secrets.moodle_password" -}}
{{- default (randAlphaNum 16) .Values.dbpMoodle.secrets.moodle_password }}
{{- end -}}

{{- define "dbpMoodle.secrets.pgsql_admin_password" -}}
{{- default (randAlphaNum 16) .Values.dbpMoodle.secrets.pgsql_admin_password }}
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
kaltura:kaltura:: {{- .Values.global.moodlePlugins.kaltura.enabled }}{{"\n"}}
wunderbyte_table:local_wunderbyte_table:local/wunderbyte_table: {{- .Values.global.moodlePlugins.booking.enabled}}{{"\n"}}
certificate:tool_certificate:admin/tool/certificate:            {{- or .Values.global.moodlePlugins.certificate.enabled .Values.global.moodlePlugins.coursecertificate.enabled }}{{"\n"}}
etherpadlite:mod_etherpadlite:mod/etherpadlite:                 {{- .Values.global.moodlePlugins.etherpadlite.enabled }}{{"\n"}}
hvp:mod_hvp:mod/hvp:                                            {{- .Values.global.moodlePlugins.hvp.enabled }}{{"\n"}}
groupselect:mod_groupselect:mod/groupselect:                    {{- .Values.global.moodlePlugins.groupselect.enabled }}{{"\n"}}
jitsi:mod_jitsi:mod/jitsi:                                      {{- .Values.global.moodlePlugins.jitsi.enabled }}{{"\n"}}
pdfannotator:mod_pdfannotator:mod/pdfannotator:                 {{- .Values.global.moodlePlugins.pdfannotator.enabled }}{{"\n"}}
skype:mod_skype:mod/skype:                                      {{- .Values.global.moodlePlugins.skype.enabled }}{{"\n"}}
zoom:mod_zoom:mod/zoom:                                         {{- .Values.global.moodlePlugins.zoom.enabled }}{{"\n"}}
booking:mod_booking:mod/booking:                                {{- .Values.global.moodlePlugins.booking.enabled }}{{"\n"}}
reengagement:mod_reengagement:mod/reengagement:                 {{- .Values.global.moodlePlugins.reengagement.enabled }}{{"\n"}}
unilabel:mod_unilabel:mod/unilabel:                             {{- .Values.global.moodlePlugins.unilabel.enabled }}{{"\n"}}
geogebra:mod_geogebra:mod/geogebra:                             {{- .Values.global.moodlePlugins.geogebra.enabled }}{{"\n"}}
choicegroup:mod_choicegroup:mod/choicegroup:                    {{- .Values.global.moodlePlugins.choicegroup.enabled }}{{"\n"}}
staticpage:local_staticpage:local/staticpage:                   {{- .Values.global.moodlePlugins.staticpage.enabled }}{{"\n"}}
heartbeat:tool_heartbeat:admin/tool/heartbeat:                  {{- .Values.global.moodlePlugins.heartbeat.enabled }}{{"\n"}}
remuiformat:format_remuiformat:course/format/remuiformat:       {{- .Values.global.moodlePlugins.remuiformat.enabled }}{{"\n"}}
tiles:format_tiles:course/format/tiles:                         {{- .Values.global.moodlePlugins.tiles.enabled }}{{"\n"}}
topcoll:format_topcoll:course/format/topcoll:                   {{- .Values.global.moodlePlugins.topcoll.enabled }}{{"\n"}}
oidc:auth_oidc:auth/oidc:                                       {{- .Values.global.moodlePlugins.oidc.enabled }}{{"\n"}}
saml2:auth_saml2:auth/saml2:                                    {{- .Values.global.moodlePlugins.saml2.enabled }}{{"\n"}}
dash:block_dash:blocks/dash:                                    {{- .Values.global.moodlePlugins.dash.enabled }}{{"\n"}}
sharing_cart:block_sharing_cart:blocks/sharing_cart:            {{- .Values.global.moodlePlugins.sharing_cart.enabled }}{{"\n"}}
xp:block_xp:blocks/xp:                                          {{- .Values.global.moodlePlugins.xp.enabled }}{{"\n"}}
coursecertificate:mod_coursecertificate:mod/coursecertificate:  {{- .Values.global.moodlePlugins.coursecertificate.enabled }}{{"\n"}}
adaptable:theme_adaptable:theme/adaptable:                      {{- .Values.global.moodlePlugins.adaptable.enabled }}{{"\n"}}
boost_union:theme_boost_union:theme/boost_union:                {{- .Values.global.moodlePlugins.boost_union.enabled }}{{"\n"}}
boost_magnific:theme_boost_magnific:theme/boost_magnific:       {{- .Values.global.moodlePlugins.boost_magnific.enabled }}{{"\n"}}
snap:theme_snap:theme/snap:                                     {{- .Values.global.moodlePlugins.snap.enabled }}{{"\n"}}

{{- end -}}
