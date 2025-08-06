{{/*
Copyright IBM, Inc. All Rights Reserved.
SPDX-License-Identifier: APACHE-2.0
*/}}

{{/* vim: set filetype=mustache: */}}

{{- define "finops-agent.clusterId" -}}
{{ default .Values.global.clusterId .Values.clusterId }}
{{- end -}}

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
Return true if the finops agent should create a secret for the federated storage config
*/}}
{{- define "finops-agent.federatedStorage.secret.create" -}}
{{- if and (or (not (empty (.Values.global.federatedStorage).existingSecret)) (not (empty (.Values.federatedStorage).existingSecret))) (.Values.federatedStorage).config }}
{{ fail "Cannot set both .Values.global.federatedStorage.existingSecret and .Values.federatedStorage.config" }}
{{- end }}
{{- if .Values.federatedStorage.config }}
true
{{- else }}
false
{{- end }}
{{- end }}

{{/*
define the name of the secret with the federated bucket config
*/}}
{{- define "finops-agent.federatedStorage.secretName" }}
{{- if (.Values.federatedStorage).existingSecret }}
{{- .Values.federatedStorage.existingSecret }}
{{- else if (.Values.global.federatedStorage).existingSecret }}
{{- .Values.global.federatedStorage.existingSecret }}
{{- else }}
{{ .Release.Name }}-federated-storage-config
{{- end }}
{{- end }}

{{- define "finops-agent.federatedStorage.fileName" }}
{{ default "federated-store.yaml" (.Values.global.federatedStorage).fileName }}
{{- end }}

{{/*
define the name of the cloudability secret
*/}}
{{- define "cloudability.secret.name" }}
{{- if .Values.agent.cloudability.secret.create }}
{{ .Release.Name }}-cloudability-secrets
{{- else }}
{{.Values.agent.cloudability.secret.existingSecret}}
{{- end }}
{{- end }}