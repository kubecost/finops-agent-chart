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
{{ fail "\n\nclusterId is required. Please set .Values.global.clusterId or .Values.clusterId" }}
{{- end -}}
{{- end -}}

{{/*
Return the proper FinOps Agent Core image name
*/}}
{{- define "finops-agent.image" -}}
{{- if .Values.fullImageName -}}
{{ .Values.fullImageName }}
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
Return true if the finops agent should create a secret for the federated storage config
*/}}
{{- define "finops-agent.federatedStorageSecretCheck" }}
{{- $globalExistingSecret := not (empty (.Values.global.federatedStorage).existingSecret) }}
{{- $localExistingSecret := not (empty (.Values.federatedStorage).existingSecret) }}
{{- $hasConfig := (.Values.federatedStorage).config }}
{{- if and (or $globalExistingSecret $localExistingSecret) $hasConfig }}
{{ fail "Cannot set both .Values.global.federatedStorage.existingSecret and .Values.federatedStorage.config" }}
{{- end }}
{{- end }}

{{- define "finops-agent.kubecostConfigCheck" }}
{{- if .Values.agent.kubecost.enabled }}
{{- if not (or .Values.federatedStorage.config .Values.global.federatedStorage.config) }}
{{- if not (or .Values.federatedStorage.existingSecret .Values.global.federatedStorage.existingSecret) }}
{{- if not (include "finops-agent.localStoreEnabled" .) }}
{{ fail "\n\nFederated storage is required when agent.kubecost.enabled is true" }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
define the name of the secret with the federated bucket config
*/}}
{{- define "finops-agent.federatedStorageSecretName" }}
{{- if (.Values.federatedStorage).existingSecret }}
{{- .Values.federatedStorage.existingSecret }}
{{- else if (.Values.global.federatedStorage).existingSecret }}
{{- .Values.global.federatedStorage.existingSecret }}
{{- else }}
{{- .Release.Name }}-federated-storage-config
{{- end }}
{{- end }}

{{- define "finops-agent.federatedStorageFileName" }}
{{- if .Values.federatedStorage.fileName }}
{{- .Values.federatedStorage.fileName }}
{{- else if (.Values.global.federatedStorage).fileName }}
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
{{- if .Values.cspPricingApiKey.apiKey }}
{{ .Release.Name }}-csp-pricing-api-key-secret
{{- else if .Values.cspPricingApiKey.existingSecretName }}
{{.Values.cspPricingApiKey.existingSecretName}}
{{- else }}
{{- "disabled" }}
{{- end }}
{{- end }}

{{- define "finops-agent.exportBucketLegacyCheck" }}
{{- if (((.Values.exportBucket).secret).config) }}
{{- fail "\n\nexportBucket.secret.config has changed. Please use federatedStorage.config instead" }}
{{- end }}
{{- if (((.Values.exportBucket).secret).existingSecret) }}
{{- fail "\n\nexportBucket.secret.existingSecret has changed. Please use federatedStorage.existingSecret instead" }}
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
{{- if not (or .Values.agent.kubecost.enabled .Values.agent.cloudability.enabled) }}
{{ printf "\nWARNING: The finops agent requires configuration.\nPlease set either agent.kubecost.enabled to true or agent.cloudability.enabled to true\n" }}
{{- else }}
{{- printf "\n\nYou have successfully installed the IBM FinOps agent!\n" }}
{{- end }}
{{- end }}