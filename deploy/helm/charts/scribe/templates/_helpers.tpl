{{/*
Common template helpers
*/}}

{{ define "scribe.name" -}}
{{ default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{ end -}}

{{ define "scribe.fullname" -}}
{{ if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := include "scribe.name" . -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "scribe.labels" -}}
app.kubernetes.io/name: {{ include "scribe.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end -}}

{{- define "scribe.selectorLabels" -}}
app.kubernetes.io/name: {{ include "scribe.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "scribe.componentName" -}}
{{- $root := index . 0 -}}
{{- $component := index . 1 -}}
{{- printf "%s-%s" (include "scribe.fullname" $root) $component | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "scribe.redisUrl" -}}
{{- if .Values.redis.enabled -}}
{{- printf "redis://%s.%s.svc.%s:%d/0" (include "scribe.componentName" (list . "redis")) .Release.Namespace .Values.global.clusterDomain (.Values.redis.service.port | int) -}}
{{- else -}}
{{- required "redisConfig.url is required when redis.enabled=false" .Values.redisConfig.url -}}
{{- end -}}
{{- end -}}

{{- define "scribe.redisHost" -}}
{{- if .Values.redis.enabled -}}
{{- printf "%s.%s.svc.%s" (include "scribe.componentName" (list . "redis")) .Release.Namespace .Values.global.clusterDomain -}}
{{- else -}}
{{- required "redisConfig.host is required when redis.enabled=false" .Values.redisConfig.host -}}
{{- end -}}
{{- end -}}

{{- define "scribe.redisPort" -}}
{{- if .Values.redis.enabled -}}
{{- .Values.redis.service.port | int -}}
{{- else -}}
{{- required "redisConfig.port is required when redis.enabled=false" .Values.redisConfig.port -}}
{{- end -}}
{{- end -}}

{{- define "scribe.dbHost" -}}
{{- if .Values.postgres.enabled -}}
{{- include "scribe.componentName" (list . "postgres") -}}
{{- else -}}
{{- required "database.host is required when postgres.enabled=false" .Values.database.host -}}
{{- end -}}
{{- end -}}

{{- /*
  scribe.dbHostEffective — the host every service SHOULD point at for DB.
  When pgbouncer.enabled=true, routes through the pgbouncer Service.
  Otherwise falls through to scribe.dbHost (direct Postgres). PgBouncer's
  own Deployment bypasses this helper and uses scribe.dbHost directly to
  avoid pointing at itself.
*/ -}}
{{- define "scribe.dbHostEffective" -}}
{{- if .Values.pgbouncer.enabled -}}
{{- include "scribe.componentName" (list . "pgbouncer") -}}
{{- else -}}
{{- include "scribe.dbHost" . -}}
{{- end -}}
{{- end -}}

{{- define "scribe.dbPortEffective" -}}
{{- if .Values.pgbouncer.enabled -}}
{{- .Values.pgbouncer.service.port | default 5432 -}}
{{- else -}}
{{- .Values.database.port -}}
{{- end -}}
{{- end -}}

{{- define "scribe.adminTokenSecretName" -}}
{{- if .Values.secrets.existingSecretName -}}
{{- .Values.secrets.existingSecretName -}}
{{- else -}}
{{- include "scribe.componentName" (list . "secrets") -}}
{{- end -}}
{{- end -}}

{{- define "scribe.botImage" -}}
{{- if .Values.global.imageTag -}}
{{- printf "scribe/scribe-bot:%s" .Values.global.imageTag -}}
{{- else if .Values.runtimeApi.browserImage -}}
{{- .Values.runtimeApi.browserImage -}}
{{- else if .Values.meetingApi.botImageName -}}
{{- .Values.meetingApi.botImageName -}}
{{- else -}}
{{- printf "%s:%s" .Values.meetingApi.image.repository .Values.meetingApi.image.tag -}}
{{- end -}}
{{- end -}}

{{- define "scribe.postgresCredentialsSecretName" -}}
{{- if .Values.postgres.enabled -}}
{{- .Values.postgres.credentialsSecretName | default "postgres-credentials" -}}
{{- else -}}
{{- required "postgres.credentialsSecretName must name a pre-existing Secret when postgres.enabled=false (keys: POSTGRES_PASSWORD, POSTGRES_USER, POSTGRES_DB)" .Values.postgres.credentialsSecretName -}}
{{- end -}}
{{- end -}}

{{- define "scribe.deploymentStrategy" -}}
{{/*
v0.10.5.3 Pack H — zero-downtime rolling update.

Pre-fix: maxSurge: 0, maxUnavailable: 1. With replicaCount: 1, this killed
the OLD pod before creating the NEW pod, causing 502s during any image
bump (e.g. the v0.10.5.2 cycle outage where dashboard + webapp went 502
because new image tags didn't exist on the registry — old pods were
already killed by the time helm upgrade tried to create the new pods).

Post-fix: maxSurge: 1, maxUnavailable: 0. NEW pod is created first;
helm waits until it's Ready before killing the OLD. With --atomic --wait
on the helm upgrade call (release-helm-upgrade-safe Make target),
failed image pulls auto-rollback without ever exposing the outage.

Works on replicaCount=1 (1 old -> 1 old + 1 new -> 1 new) and
replicaCount>1 (rolling progresses one extra at a time).
*/}}
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1
    maxUnavailable: 0
{{- end -}}

{{/*
v0.10.5 Pack C.5 — Redis durability paired invariant.

AOF (appendonly + appendfsync) is the per-write durability mechanism.
`stop-writes-on-bgsave-error: no` allows writes to continue when the
snapshot mechanism fails (block-volume hiccup, disk-full, fsync stall) —
which is non-blocking when AOF is on. Setting `stop-writes-on-bgsave-error: yes`
WITHOUT `appendonly: yes` would create a write-loss window: Redis would
accept writes that aren't durable anywhere if BGSAVE fails. Refuse to render.

The 2026-04-21 redis-storage-cascade incident was triggered by exactly
this anti-pattern: BGSAVE failed, default `stop-writes-on-bgsave-error: yes`
froze writes for 46 min. With AOF + bgsave-error: no, BGSAVE failures
become non-blocking. Industry-standard Redis-as-stream-buffer config.
*/}}
{{- define "scribe.validateRedisDurability" -}}
{{- $aof := .Values.redis.durability.appendonly | default "yes" -}}
{{- $bgsaveBlocks := .Values.redis.durability.stopWritesOnBgsaveError | default "no" -}}
{{- if and (eq $bgsaveBlocks "yes") (ne $aof "yes") -}}
{{- required "INVALID redis.durability config: stopWritesOnBgsaveError=yes requires appendonly=yes (paired AOF + BGSAVE durability invariant — see v0.10.5 Pack C.5). Without AOF, blocking writes on BGSAVE failure means writes that arrive while BGSAVE is failing have no durable record anywhere." "" -}}
{{- end -}}
{{- end -}}
