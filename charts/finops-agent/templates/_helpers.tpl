{{/*
Copyright IBM, Inc. All Rights Reserved.
SPDX-License-Identifier: APACHE-2.0
*/}}

{{/* vim: set filetype=mustache: */}}

{{- define "finops-agent.clusterId" -}}
{{- if .Values.global.clusterId -}}
{{ .Values.global.clusterId }}
{{- else if .Values.clusterId -}}
{{ .Values.clusterId }}
{{- else -}}
{{ fail "\n\nclusterId is required. Please set .Values.global.clusterId" }}
{{- end -}}
{{- end -}}

{{/*
Return the proper FinOps Agent Core image name
*/}}
{{- define "finops-agent.image" -}}
{{- if .Values.fullImageName -}}
{{ .Values.fullImageName }}
{{- else if .Values.global.finopsAgentFullImageName -}}
{{ .Values.global.finopsAgentFullImageName }}
{{- else -}}
{{ include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global) }}
{{- end -}}
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
define the name of the secret with the federated bucket config
*/}}
{{- define "finops-agent.federatedStorageSecretName" }}
{{- if (.Values.global.federatedStorage).existingSecretName }}
{{- .Values.global.federatedStorage.existingSecretName }}
{{- else }}
{{- .Release.Name }}-federated-storage-config
{{- end }}
{{- end }}

{{- define "finops-agent.federatedStorageFileName" }}
{{- if .Values.global.federatedStorage.fileName }}
{{- .Values.global.federatedStorage.fileName }}
{{- else }}
{{- "federated-store.yaml" }}
{{- end }}
{{- end }}

{{/*
define the name of the cloudability secret
*/}}
{{- define "cloudability.secret.name" }}
{{- if .Values.agent.cloudability.secret.create }}
{{ .Release.Name }}-cloudability-secrets
{{- else if .Values.agent.cloudability.secret.existingSecret }}
{{.Values.agent.cloudability.secret.existingSecret}}
{{- else }}
{{- "" }}
{{- end }}
{{- end }}

{{/*
define the name of the csp pricing api key secret
*/}}
{{- define "finops-agent.cspPricingApiKeySecretName" }}
{{- if .Values.global.cspPricingApiKey.apiKey }}
{{ .Release.Name }}-csp-pricing-api-key-secret
{{- else if .Values.global.cspPricingApiKey.existingSecretName }}
{{.Values.global.cspPricingApiKey.existingSecretName}}
{{- else }}
{{- "disabled" }}
{{- end }}
{{- end }}

{{- define "finops-agent.exportBucketLegacyCheck" }}
{{- if (((.Values.exportBucket).secret).config) }}
{{- fail "\n\nexportBucket.secret.config has changed. Please use global.federatedStorage.config instead" }}
{{- end }}
{{- if (((.Values.exportBucket).secret).existingSecret) }}
{{- fail "\n\nexportBucket.secret.existingSecret has changed. Please use global.federatedStorage.existingSecretName instead" }}
{{- end }}
{{- end }}

{{- define "finops-agent.localStoreEnabled" }}
{{- if .Values.localStoreEnabled }}
{{- true }}
{{- else }}
{{- false }}
{{- end }}
{{- end }}

{{/*
check if the finops agent is configured to send data to the cloudability platform or kubecost.
We may want for this to be a failure if the agent cannot send historical data that was collected prior to being correctly configured.
*/}}
{{- define "finops-agent.configCheck" }}
{{- if not (or (.Values.global.federatedStorage.existingSecretName) (.Values.global.federatedStorage.config) (.Values.agent.cloudability.enabled)) }}
{{ printf "\nWARNING: The finops agent requires configuration.\nFor Kubecost, please provide a federated storage config\nFor Cloudability, set agent.cloudability.enabled to true\n" }}
{{- else }}
{{- printf "\n\nYou have successfully installed the IBM FinOps agent!\n" }}
{{- end }}
{{- end }}

{{- define "finops-agent.kubecostEnabled" }}
{{- if or (.Values.global.federatedStorage.existingSecretName) (.Values.global.federatedStorage.config) (.Values.localStoreEnabled) }}
{{- true }}
{{- else }}
{{- false }}
{{- end }}
{{- end }}