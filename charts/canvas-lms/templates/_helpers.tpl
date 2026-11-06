{{- define "canvas.fullname" -}}{{- printf "%s" .Release.Name | trunc 50 | trimSuffix "-" -}}{{- end -}}
{{- define "canvas.labels" -}}
app.kubernetes.io/name: canvas-lms
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}
{{- define "canvas.selector" -}}
app.kubernetes.io/name: canvas-lms
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
{{- define "canvas.image" -}}
{{- if .Values.image.digest -}}{{ .Values.image.repository }}@{{ .Values.image.digest }}{{- else -}}{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}{{- end -}}
{{- end -}}
{{- define "canvas.dbHost" -}}{{ .Values.database.host | default (printf "%s-postgres" (include "canvas.fullname" .)) }}{{- end -}}
{{- define "canvas.redisHost" -}}{{ printf "%s-redis" (include "canvas.fullname" .) }}{{- end -}}
{{- define "canvas.env" -}}
- { name: RAILS_ENV, value: production }
- { name: RAILS_LOG_TO_STDOUT, value: "1" }
- { name: CANVAS_LMS_ADMIN_EMAIL, value: {{ .Values.canvas.adminEmail | quote }} }
- { name: CANVAS_LMS_ACCOUNT_NAME, value: {{ .Values.canvas.accountName | quote }} }
- { name: CANVAS_LMS_STATS_COLLECTION, value: opt_out }
{{- end -}}
{{- define "canvas.envFrom" -}}
- secretRef: { name: {{ required "canvas.existingSecret is required (no secrets in values)" .Values.canvas.existingSecret }} }
{{- end -}}
{{- define "canvas.volumes" -}}
- name: config-files
  configMap: { name: {{ include "canvas.fullname" . }}-config }
{{- if .Values.canvas.ltiKeysSecret }}
- name: lti-keys
  secret: { secretName: {{ .Values.canvas.ltiKeysSecret }} }
{{- end }}
{{- if eq .Values.storage.mode "pvc" }}
- name: files
  persistentVolumeClaim: { claimName: {{ include "canvas.fullname" . }}-files }
{{- end }}
{{- end -}}
{{- define "canvas.mounts" -}}
{{- range $f, $_ := (include "canvas.configFiles" . | fromYaml) }}
- { name: config-files, mountPath: /usr/src/app/config/{{ $f | replace "__" "/" }}, subPath: {{ $f }}, readOnly: true }
{{- end }}
{{- if .Values.canvas.ltiKeysSecret }}
- { name: lti-keys, mountPath: /etc/canvas/lti-keys, readOnly: true }
{{- end }}
{{- if eq .Values.storage.mode "pvc" }}
- { name: files, mountPath: /usr/src/app/tmp/files }
{{- end }}
{{- end -}}
