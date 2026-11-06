{{- define "canvas.configFiles" -}}
domain.yml: |
  production:
    domain: {{ .Values.canvas.domain | quote }}
    ssl: {{ eq .Values.canvas.scheme "https" }}
database.yml: |
  production:
    adapter: postgresql
    host: {{ include "canvas.dbHost" . | quote }}
    port: {{ .Values.database.port }}
    database: {{ .Values.database.name | quote }}
    username: {{ .Values.database.user | quote }}
    password: <%= ENV.fetch("DB_PASSWORD") %>
    encoding: utf8
    timeout: 5000
    prepared_statements: false
redis.yml: |
  production:
    url: {{ if .Values.redis.url }}{{ .Values.redis.url | quote }}{{ else }}<%= "redis://:#{ENV.fetch('REDIS_PASSWORD')}@{{ include "canvas.redisHost" . }}:6379/0" %>{{ end }}
    connect_timeout: 0.5
cache_store.yml: |
  production:
    cache_store: redis_cache_store
security.yml: |
  production:
    encryption_key: <%= ENV.fetch("ENCRYPTION_KEY") %>
    lti_iss: {{ .Values.canvas.ltiIssuer | default (printf "%s://%s" .Values.canvas.scheme .Values.canvas.domain) | quote }}
dynamic_settings.yml: |
  production:
    config:
      canvas:
        dummy: {}
  {{- if .Values.canvas.ltiKeysSecret }}
    store:
      canvas:
        lti-keys:
          jwk-past.json: <%= File.read("/etc/canvas/lti-keys/jwk-past.json").to_json %>
          jwk-present.json: <%= File.read("/etc/canvas/lti-keys/jwk-present.json").to_json %>
          jwk-future.json: <%= File.read("/etc/canvas/lti-keys/jwk-future.json").to_json %>
  {{- end }}
file_store.yml: |
  production:
  {{- if eq .Values.storage.mode "s3" }}
    storage: s3
  {{- else }}
    storage: local
    path_prefix: tmp/files
  {{- end }}
delayed_jobs.yml: |
  default:
    workers:
    - queue: canvas_queue
environments__production-local.rb: |
  config.force_ssl = false
{{- range $k, $v := .Values.canvas.extraConfigFiles }}
{{ $k }}: |
{{ tpl $v $ | indent 2 }}
{{- end }}
{{- end -}}
