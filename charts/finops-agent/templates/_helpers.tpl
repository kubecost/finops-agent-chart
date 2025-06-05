{{/*
Copyright IBM, Inc. All Rights Reserved.
SPDX-License-Identifier: APACHE-2.0
*/}}

{{/* vim: set filetype=mustache: */}}

{{/*
Return the proper FinOps Agent&trade; Core image name
*/}}
{{- define "finops-agent.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global) }}
{{- end -}}



{{/*
Return the proper Docker Image Registry Secret Names
*/}}
{{- define "finops-agent.imagePullSecrets" -}}
{{ include "common.images.pullSecrets" (dict "images" (list .Values.image ) "global" .Values.global) }}
{{- end -}}

{{/*
Create the name of the ServiceAccount to use
*/}}
{{- define "finops-agent.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "common.names.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
define the name of the export secret bucket
*/}}
{{- define "exportBucket.secret.name" }}
{{ .Release.Name }}-export-bucket-config
{{- end }}

{{/*
define the name of the cloudability secret
*/}}
{{- define "cloudability.secret.name" }}
{{- if .Values.agent.cloudability.secret.create }}
{{ .Release.Name }}-export-bucket-config
{{- else }}
{{.Values.agent.cloudability.secret.existingSecret}}
{{- end }}
{{- end }}