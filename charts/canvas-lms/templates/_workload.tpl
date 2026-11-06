{{- define "canvas.waitForDb" -}}
- name: wait-for-schema
  image: {{ include "canvas.image" . }}
  imagePullPolicy: {{ .Values.image.pullPolicy }}
  securityContext: {{- toYaml .Values.restrictedSecurityContext | nindent 4 }}
  command: ["bash", "-c"]
  args:
    - until PGPASSWORD="$DB_PASSWORD" psql -h {{ include "canvas.dbHost" . }} -U {{ .Values.database.user }} -d {{ .Values.database.name }} -tAc "select 1 from schema_migrations limit 1" | grep -q 1; do echo waiting for migrations; sleep 5; done
  envFrom:
    - secretRef: { name: {{ .Values.canvas.existingSecret }} }
{{- end -}}
{{- define "canvas.spread" -}}
{{- if .root.Values.topologySpread }}
topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: kubernetes.io/hostname
    whenUnsatisfiable: ScheduleAnyway
    labelSelector:
      matchLabels: {{- include "canvas.selector" .root | nindent 8 }}
        app.kubernetes.io/component: {{ .component }}
{{- end }}
{{- end -}}
