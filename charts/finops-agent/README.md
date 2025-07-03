<!--- app-name: IBM FinOps Agent&trade; IBM FinOps Agent&trade; -->

# Helm Chart for the IBM FinOps Agent

This helm chart deploys the IBM FinOps Agent, which supports both Cloudability and Kubecost.

## TL;DR

```console
helm repo add ibm-finops https://kubecost.github.io/finops-agent-chart
helm install my-release ibm-finops/finops-agent-chart --set clusterId='my-cluster-id'
```

## Introduction

This chart bootstraps an IBM FinOps Agent deployment on a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites

- Kubernetes 1.31+
- Helm 3.8.0+
- PV provisioner support in the underlying infrastructure

## Installing the Chart

To install the chart with the release name `my-release`:

```console
helm repo add ibm-finops https://kubecost.github.io/finops-agent-chart
helm install my-release ibm-finops/finops-agent-chart --set clusterId='my-cluster-id'
```

These commands deploy the FinOps Agent on the Kubernetes cluster in the default configuration. The [Parameters](#parameters) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Configuration and installation details

### FinOps Agent pod Service

This chart installs a deployment with the following configuration:

```text
                 ----------------
                |  FinOps Agent  |
                |      svc       |
                 ----------------
                        |
                        \/
                  --------------
                 | FinOps Agent |
                 |     Pod      |
                  --------------
```

The service is used primarily to provide diagnostics information and a scrape target. The FinOps Agent itself does not provide data querying, that is supported by the suite of IBM products that utilize the agent data. 

### Configure the Export Bucket

The IBM FinOps Agent can collect and store limited data on its local storage. To be viewed and used for FinOps activities, however, the data must be uploaded to an object store so that it can be consumed by products in the IBM FinOps suite like Cloudability and Kubecost. 

The bucket secret syntax itself is specified further in TODO - INSERT LINK 

To provide a secret, see the `exportBucket` settings in the parameters section. The chart allows the user to provide an already installed secret via the `existingSecret` parameter. Alternatively, the `create` setting can be set to true, which will allow the chart to create a secret using the contents of the `config` setting. 

### Resource requests and limits

Bitnami charts allow setting resource requests and limits for all containers inside the chart deployment. These are inside the `resources` value (check parameter table). Setting requests is essential for production workloads and these should be adapted to your specific use case.

To make this process easier, the chart contains the `resourcesPreset` values, which automatically sets the `resources` section according to different presets. Check these presets in [the bitnami/common chart](https://github.com/bitnami/charts/blob/main/bitnami/common/templates/_resources.tpl#L15). However, in production workloads using `resourcesPreset` is discouraged as it may not fully adapt to your specific needs. Find more information on container resource management in the [official Kubernetes documentation](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/).

### Prometheus metrics

This chart can be integrated with Prometheus by setting `metrics.enabled` to `true`. This will add the required annotations on the FinOps Agent service to be automatically scraped by Prometheus.

#### Prometheus requirements

It is necessary to have a working installation of Prometheus or Prometheus Operator for the integration to work. Install the [Bitnami Prometheus helm chart](https://github.com/bitnami/charts/tree/main/bitnami/prometheus) or the [Bitnami Kube Prometheus helm chart](https://github.com/bitnami/charts/tree/main/bitnami/kube-prometheus) to easily have a working Prometheus in your cluster.

#### Integration with Prometheus Operator

The chart can deploy `ServiceMonitor` objects for integration with Prometheus Operator installations. To do so, set the value `metrics.serviceMonitor.enabled=true`. Ensure that the Prometheus Operator `CustomResourceDefinitions` are installed in the cluster or it will fail with the following error:

```text
no matches for kind "ServiceMonitor" in version "monitoring.coreos.com/v1"
```

### Adding extra environment variables

In case you want to add extra environment variables, you can use the `extraEnvVars` property.

```yaml
extraEnvVars:
  - name: MY_EXTRA_ENV_VAR
    value: "true"
```

### Setting Pod's affinity

This chart allows you to set your custom affinity using the `affinity` parameter(s). Find more information about Pod's affinity in the [kubernetes documentation](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity).

As an alternative, you can use of the preset configurations for pod affinity, pod anti-affinity, and node affinity available at the [bitnami/common](https://github.com/bitnami/charts/tree/main/bitnami/common#affinities) chart. To do so, set the `podAffinityPreset`, `podAntiAffinityPreset`, or `nodeAffinityPreset` parameters.


## Persistence

Local data can be persisted by default using PVC(s), to survive restarts until uploaded to bucket storage. You can disable the persistence setting the `persistence.enabled` parameter to `false`.

A default `StorageClass` is needed in the Kubernetes cluster to dynamically provision the volumes. Specify another StorageClass in the `persistence.storageClass` or set `persistence.existingClaim` if you have already existing persistent volumes to use.


## Parameters

### Global Parameters

| Name | Description | Default |
|------|-------------|---------|
| `global.imageRegistry` | Global Docker image registry | `""` |
| `global.imagePullSecrets` | Global Docker registry secret names as an array | `[]` |
| `global.defaultStorageClass` | Global default StorageClass for Persistent Volume(s) | `""` |
| `global.security.allowInsecureImages` | Allows skipping image verification | `false` |
| `global.compatibility.openshift.adaptSecurityContext` | Adapt the securityContext sections of the deployment to make them compatible with Openshift restricted-v2 SCC | `auto` |

### Common Parameters

| Name | Description | Default |
|------|-------------|---------|
| `clusterId` | The id of the cluster REQUIRED | `""` |
| `kubeVersion` | Override Kubernetes version | `""` |
| `apiVersions` | Override Kubernetes API versions reported by .Capabilities | `[]` |
| `nameOverride` | String to partially override common.names.name | `""` |
| `fullnameOverride` | String to fully override common.names.fullname | `""` |
| `namespaceOverride` | String to fully override common.names.namespace. This would be used to deploy the finops-agent resources to a different namespace than the release itself | `""` |
| `clusterDomain` | Default Kubernetes cluster domain | `cluster.local` |
| `commonAnnotations` | Annotations to add to all deployed objects | `{}` |
| `commonLabels` | Labels to add to all deployed objects | `{}` |
| `extraDeploy` | Array of extra objects to deploy with the release | `[]` |
| `useHelmHooks` | Enable use of Helm hooks if needed, e.g. on pre-install jobs | `true` |

### IBM FinOps Agent Core Parameters

| Name | Description | Default |
|------|-------------|---------|
| `image.registry` | IBM FinOps Agent image registry | `gcr.io` |
| `image.repository` | IBM FinOps Agent image repository | `guestbook-227502/agent` |
| `image.tag` | IBM FinOps Agent image tag (immutable tags are recommended) | `v0.0.15` |
| `image.digest` | IBM FinOps Agent image digest in the way sha256:aa.... Please note this parameter, if set, will override the tag | `""` |
| `image.pullPolicy` | IBM FinOps Agent image pull policy | `IfNotPresent` |
| `image.pullSecrets` | Specify docker-registry secret names as an array | `[]` |
| `image.debug` | Specify if debug logs should be enabled | `false` |
| `gcpKey` | GCP API key if deploying to GCP. This can be read only permissions, this is used to fetch current pricing of resources | `""` |
| `logLevel` | The log level for the finops agent | `info` |

### Export Bucket Configuration

| Name | Description | Default |
|------|-------------|---------|
| `exportBucket.secret.create` | Create a secret for the export bucket | `true` |
| `exportBucket.secret.config` | The config for the export bucket | `""` |
| `exportBucket.secret.existingSecret` | The name of an existing secret to use for the export bucket. Note, you cannot set both `create` and `existingSecret` | `""` |

### Agent Configuration

| Name | Description                                                                                                                                                                                | Default   |
|------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------|
| `agent.collectorDataSource.enabled` | Enable the collector data source                                                                                                                                                           | `true`    |
| `agent.collectorDataSource.scrapeInterval` | The scrape interval for the collector data source                                                                                                                                          | `10s`     |
| `agent.collectorDataSource.networkPort` | The network port for the collector data source                                                                                                                                             | `3001`    |
| `agent.collectorDataSource.retentionResolution10m` | The retention resolution for the collector data source                                                                                                                                     | `10m`     |
| `agent.collectorDataSource.retentionResolution1h` | The retention resolution for the collector data source                                                                                                                                     | `1h`      |
| `agent.collectorDataSource.retentionResolution1d` | The retention resolution for the collector data source                                                                                                                                     | `1d`      |
| `agent.kubecost.enabled` | Enable the kubecost data source                                                                                                                                                            | `true`    |
| `agent.cloudability.enabled` | Enable the cloudability data source                                                                                                                                                        | `true`    |
| `agent.cloudability.localWorkingDir` | The local working directory for the cloudability data source                                                                                                                               | `/tmp`    |
| `agent.cloudability.uploadRegion` | The upload region for the cloudability data source                                                                                                                                         | `us`      |
| `agent.cloudability.httpsClientTimeout` | Amount (in seconds) of time the http client has before timing out requests. Might need to be increased to clusters with large payloads                                                     | `60`      |
| `agent.cloudability.uploadRetryCount` | Number of attempts the agent will retry to upload a payload                                                                                                                                | `5`       |
| `agent.cloudability.outboundProxyInsecure` | When true, does not verify certificates when making TLS connections.                                                                                                                       | `false`   |
| `agent.cloudability.parseMetricData` | When true, core files will be parsed and non-relevant data will be removed prior to upload.                                                                                                | `false`   |
| `agent.cloudability.emissionInterval` | A duration string of how often samples are emitted to the cloudability uploader                                                                                                            | `3m`   |
| `agent.cloudability.outboundProxy` | The URL of an outbound HTTP/HTTPS proxy for the agent to use (eg: http://x.x.x.x:8080). The URL must contain the scheme prefix (http:// or https://)                                       | `""` |
| `agent.cloudability.outboundProxyAuth` | Basic Authentication credentials to be used with the defined outbound proxy. If your outbound proxy requires basic authentication credentials can be defined in the form username:password | `""` |
| `agent.cloudability.secret.create` | Create a secret for the cloudability data source                                                                                                                                           | `true`    |
| `agent.cloudability.secret.existingSecret` | The name of an existing secret to use for the cloudability data source                                                                                                                     | `""`      |
| `agent.cloudability.secret.cloudabilityAccessKey` | The cloudability access key for the cloudability data source                                                                                                                               | `""`      |
| `agent.cloudability.secret.cloudabilitySecretKey` | The cloudability secret key for the cloudability data source                                                                                                                               | `""`      |
| `agent.cloudability.secret.customAzureClientSecret` | The cloudability client secret for azure blob upload                                                                                                                                   | `""`      |
| `agent.cloudability.secret.cloudabilityEnvId` | The cloudability env id for the cloudability data source                                                                                                                                   | `""`      |
| `agent.cloudability.pathToCloudabilitySecrets` | The path to the location on the filesystem the cloudability secrets are stored                                                                                                             | `"/opt/cloudability"`      |
| `agent.cloudability.keyAccessFile` | The name of the keyAccessFile                                                                                                                                                              | `"CLOUDABILITY_KEY_ACCESS"`      |
| `agent.cloudability.keySecretFile` | The name of the keySecretFile                                                                                                                                                              | `"CLOUDABILITY_KEY_SECRET"`      |
| `agent.cloudability.envIDFile` | The name of the envIDFile                                                                                                                                                                  | `"CLOUDABILITY_ENV_ID"`      |
| `agent.cloudability.customAzureBlobClientSecretFile` | The name of the customAzureBlobClientSecretFile                                                                                                                                                                           | `"CLOUDABILITY_CUSTOM_AZURE_BLOB_CLIENT_SECRET"`      |

### Deployment Parameters

| Name | Description | Default |
|------|-------------|---------|
| `command` | Override default container command (useful when using custom images) | `[]` |
| `args` | Override default container args (useful when using custom images) | `[]` |
| `extraEnvVars` | Array with extra environment variables to add to the FinOps Agent container | `[]` |
| `extraEnvVarsCM` | Name of existing ConfigMap containing extra env vars for the FinOps Agent container | `""` |
| `extraEnvVarsSecret` | Name of existing Secret containing extra env vars for the FinOps Agent container | `""` |
| `containerPorts.http` | The FinOps Agent container HTTP port | `9003` |
| `extraContainerPorts` | Optionally specify extra list of additional ports for the FinOps Agent container | `[]` |
| `resourcesPreset` | Set container resources according to one common preset (allowed values: none, nano, micro, small, medium, large, xlarge, 2xlarge). This is ignored if resources is set. | `small` |
| `resources` | Set container requests and limits for different resources like CPU or memory | `{}` |

### Security Context Parameters

| Name | Description | Default |
|------|-------------|---------|
| `podSecurityContext.enabled` | Enable the FinOps Agent pod's Security Context | `true` |
| `podSecurityContext.fsGroupChangePolicy` | Set filesystem group change policy | `Always` |
| `podSecurityContext.sysctls` | Set kernel settings using the sysctl interface | `[]` |
| `podSecurityContext.supplementalGroups` | Set filesystem extra groups | `[]` |
| `podSecurityContext.fsGroup` | Set the FinOps Agent pod's Security Context fsGroup | `1001` |
| `containerSecurityContext.enabled` | Enable container Security Context | `true` |
| `containerSecurityContext.seLinuxOptions` | Set SELinux options in container | `{}` |
| `containerSecurityContext.runAsUser` | Set containers' Security Context runAsUser | `1001` |
| `containerSecurityContext.runAsGroup` | Set containers' Security Context runAsGroup | `1001` |
| `containerSecurityContext.runAsNonRoot` | Set container's Security Context runAsNonRoot | `true` |
| `containerSecurityContext.privileged` | Set container's Security Context privileged | `false` |
| `containerSecurityContext.readOnlyRootFilesystem` | Set container's Security Context readOnlyRootFilesystem | `true` |
| `containerSecurityContext.allowPrivilegeEscalation` | Set container's Security Context allowPrivilegeEscalation | `false` |
| `containerSecurityContext.capabilities.drop` | List of capabilities to be dropped | `["ALL"]` |
| `containerSecurityContext.seccompProfile.type` | Set container's Security Context seccomp profile | `RuntimeDefault` |

### Probes Parameters

| Name | Description | Default |
|------|-------------|---------|
| `startupProbe.enabled` | Enable startupProbe on the container | `false` |
| `startupProbe.initialDelaySeconds` | Initial delay seconds for startupProbe | `10` |
| `startupProbe.periodSeconds` | Period seconds for startupProbe | `10` |
| `startupProbe.timeoutSeconds` | Timeout seconds for startupProbe | `1` |
| `startupProbe.failureThreshold` | Failure threshold for startupProbe | `3` |
| `startupProbe.successThreshold` | Success threshold for startupProbe | `1` |
| `livenessProbe.enabled` | Enable livenessProbe on FinOps Agent container | `true` |
| `livenessProbe.initialDelaySeconds` | Initial delay seconds for livenessProbe | `10` |
| `livenessProbe.periodSeconds` | Period seconds for livenessProbe | `10` |
| `livenessProbe.timeoutSeconds` | Timeout seconds for livenessProbe | `1` |
| `livenessProbe.failureThreshold` | Failure threshold for livenessProbe | `3` |
| `livenessProbe.successThreshold` | Success threshold for livenessProbe | `1` |
| `readinessProbe.enabled` | Enable readinessProbe on FinOps Agent container | `true` |
| `readinessProbe.initialDelaySeconds` | Initial delay seconds for readinessProbe | `10` |
| `readinessProbe.periodSeconds` | Period seconds for readinessProbe | `10` |
| `readinessProbe.timeoutSeconds` | Timeout seconds for readinessProbe | `1` |
| `readinessProbe.failureThreshold` | Failure threshold for readinessProbe | `3` |
| `readinessProbe.successThreshold` | Success threshold for readinessProbe | `1` |
| `customStartupProbe` | Override default startup probe | `{}` |
| `customLivenessProbe` | Override default liveness probe | `{}` |
| `customReadinessProbe` | Override default readiness probe | `{}` |

### Pod Affinity Parameters

| Name | Description | Default |
|------|-------------|---------|
| `podAffinityPreset` | FinOps Agent Pod affinity preset. Ignored if `affinity` is set. Allowed values: `soft` or `hard` | `""` |
| `podAntiAffinityPreset` | FinOps Agent Pod anti-affinity preset. Ignored if `affinity` is set. Allowed values: `soft` or `hard` | `soft` |
| `nodeAffinityPreset.type` | FinOps Agent Node affinity preset type. Ignored if `affinity` is set. Allowed values: `soft` or `hard` | `""` |
| `nodeAffinityPreset.key` | FinOps Agent Node label key to match Ignored if `affinity` is set. | `""` |
| `nodeAffinityPreset.values` | FinOps Agent Node label values to match. Ignored if `affinity` is set. | `[]` |
| `affinity` | FinOps Agent Affinity for pod assignment | `{}` |
| `nodeSelector` | FinOps Agent Node labels for pod assignment | `{}` |
| `tolerations` | FinOps Agent Tolerations for pod assignment | `[]` |

### Pod Configuration Parameters

| Name | Description | Default |
|------|-------------|---------|
| `podAnnotations` | Annotations for FinOps Agent pod | `{}` |
| `podLabels` | Extra labels for FinOps Agent pod | `{}` |
| `hostAliases` | FinOps Agent pods host aliases | `[]` |
| `updateStrategy.type` | FinOps Agent deployment strategy type | `Recreate` |
| `priorityClassName` | FinOps Agent pods' priorityClassName | `""` |
| `revisionHistoryLimit` | FinOps Agent deployment revision history limit | `10` |
| `schedulerName` | Name of the k8s scheduler (other than default) | `""` |
| `topologySpreadConstraints` | Topology Spread Constraints for pod assignment | `[]` |
| `lifecycleHooks` | Lifecycle hooks for the FinOps Agent container(s) to automate configuration before or after startup | `{}` |
| `extraVolumeMounts` | Optionally specify extra list of additional volumeMounts for the FinOps Agent pods | `[]` |
| `extraVolumes` | Optionally specify extra list of additional volumes for the FinOps Agent pods | `[]` |
| `sidecars` | Add additional sidecar containers to the FinOps Agent pod(s) | `[]` |
| `initContainers` | Add additional init-containers to the FinOps Agent pod(s) | `[]` |

### Service Parameters

| Name | Description | Default |
|------|-------------|---------|
| `service.enabled` | Enable a clusterIP service for the FinOps Agent | `true` |
| `service.type` | Kubernetes service type | `ClusterIP` |
| `service.ports.http` | The FinOps Agent HTTP port | `80` |
| `service.clusterIP` | The FinOps Agent service Cluster IP | `""` |
| `service.extraPorts` | Extra port to expose on the FinOps Agent service | `[]` |
| `service.annotations` | Additional custom annotations for the FinOps Agent service | `{}` |

### Metrics Parameters

| Name | Description | Default |
|------|-------------|---------|
| `metrics.enabled` | Enable the export of Prometheus metrics | `false` |
| `metrics.serviceMonitor.enabled` | if `true`, creates a Prometheus Operator ServiceMonitor (also requires `metrics.enabled` to be `true`) | `false` |
| `metrics.serviceMonitor.namespace` | Namespace in which Prometheus is running | `""` |
| `metrics.serviceMonitor.labels` | Additional labels that can be used so ServiceMonitor will be discovered by Prometheus | `{}` |
| `metrics.serviceMonitor.interval` | Interval at which metrics should be scraped | `""` |
| `metrics.serviceMonitor.scrapeTimeout` | Timeout after which the scrape is ended | `""` |
| `metrics.serviceMonitor.relabelings` | RelabelConfigs to apply to samples before scraping | `[]` |
| `metrics.serviceMonitor.metricRelabelings` | MetricRelabelConfigs to apply to samples before ingestion | `[]` |
| `metrics.serviceMonitor.selector` | Prometheus instance selector labels | `{}` |
| `metrics.serviceMonitor.honorLabels` | honorLabels chooses the metric's labels on collisions with target labels | `false` |

### Persistence Parameters

| Name | Description | Default |
|------|-------------|---------|
| `persistence.enabled` | Enable FinOps Agent data persistence for WAL and other local data | `true` |
| `persistence.existingClaim` | A manually managed Persistent Volume and Claim | `""` |
| `persistence.storageClass` | PVC Storage Class for the FinOps Agent data volume | `""` |
| `persistence.accessModes` | Persistent Volume Access Modes | `["ReadWriteOnce"]` |
| `persistence.size` | PVC Storage Request for the FinOps Agent data volume | `8Gi` |
| `persistence.dataSource` | Custom PVC data source | `{}` |
| `persistence.annotations` | Additional custom annotations for the PVC | `{}` |
| `persistence.selector` | Selector to match an existing Persistent Volume for the FinOps Agent data PVC | `{}` |
| `persistence.mountPath` | Mount path of the IBM FinOps Agent data volume | `/opt/finops-agent` |

### Service Account Parameters

| Name | Description | Default |
|------|-------------|---------|
| `serviceAccount.create` | Enable creation of ServiceAccount for IBM FinOps Agent pods | `true` |
| `serviceAccount.name` | Name of the service account to use. If not set and `create` is `true`, a name is generated | `""` |
| `serviceAccount.automountServiceAccountToken` | Allows auto mount of ServiceAccountToken on the serviceAccount created | `true` |
| `serviceAccount.annotations` | Additional custom annotations for the ServiceAccount | `{}` |

### RBAC Parameters

| Name | Description | Default |
|------|-------------|---------|
| `rbac.create` | Whether to create & use RBAC resources or not | `true` |
| `rbac.clusterRole.create` | Whether to create & use ClusterRole resources or not | `true` |


## License

                                 Apache License
                           Version 2.0, January 2004
                        http://www.apache.org/licenses/

   TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

   1. Definitions.

      "License" shall mean the terms and conditions for use, reproduction,
      and distribution as defined by Sections 1 through 9 of this document.

      "Licensor" shall mean the copyright owner or entity authorized by
      the copyright owner that is granting the License.

      "Legal Entity" shall mean the union of the acting entity and all
      other entities that control, are controlled by, or are under common
      control with that entity. For the purposes of this definition,
      "control" means (i) the power, direct or indirect, to cause the
      direction or management of such entity, whether by contract or
      otherwise, or (ii) ownership of fifty percent (50%) or more of the
      outstanding shares, or (iii) beneficial ownership of such entity.

      "You" (or "Your") shall mean an individual or Legal Entity
      exercising permissions granted by this License.

      "Source" form shall mean the preferred form for making modifications,
      including but not limited to software source code, documentation
      source, and configuration files.

      "Object" form shall mean any form resulting from mechanical
      transformation or translation of a Source form, including but
      not limited to compiled object code, generated documentation,
      and conversions to other media types.

      "Work" shall mean the work of authorship, whether in Source or
      Object form, made available under the License, as indicated by a
      copyright notice that is included in or attached to the work
      (an example is provided in the Appendix below).

      "Derivative Works" shall mean any work, whether in Source or Object
      form, that is based on (or derived from) the Work and for which the
      editorial revisions, annotations, elaborations, or other modifications
      represent, as a whole, an original work of authorship. For the purposes
      of this License, Derivative Works shall not include works that remain
      separable from, or merely link (or bind by name) to the interfaces of,
      the Work and Derivative Works thereof.

      "Contribution" shall mean any work of authorship, including
      the original version of the Work and any modifications or additions
      to that Work or Derivative Works thereof, that is intentionally
      submitted to Licensor for inclusion in the Work by the copyright owner
      or by an individual or Legal Entity authorized to submit on behalf of
      the copyright owner. For the purposes of this definition, "submitted"
      means any form of electronic, verbal, or written communication sent
      to the Licensor or its representatives, including but not limited to
      communication on electronic mailing lists, source code control systems,
      and issue tracking systems that are managed by, or on behalf of, the
      Licensor for the purpose of discussing and improving the Work, but
      excluding communication that is conspicuously marked or otherwise
      designated in writing by the copyright owner as "Not a Contribution."

      "Contributor" shall mean Licensor and any individual or Legal Entity
      on behalf of whom a Contribution has been received by Licensor and
      subsequently incorporated within the Work.

   2. Grant of Copyright License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      copyright license to reproduce, prepare Derivative Works of,
      publicly display, publicly perform, sublicense, and distribute the
      Work and such Derivative Works in Source or Object form.

   3. Grant of Patent License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      (except as stated in this section) patent license to make, have made,
      use, offer to sell, sell, import, and otherwise transfer the Work,
      where such license applies only to those patent claims licensable
      by such Contributor that are necessarily infringed by their
      Contribution(s) alone or by combination of their Contribution(s)
      with the Work to which such Contribution(s) was submitted. If You
      institute patent litigation against any entity (including a
      cross-claim or counterclaim in a lawsuit) alleging that the Work
      or a Contribution incorporated within the Work constitutes direct
      or contributory patent infringement, then any patent licenses
      granted to You under this License for that Work shall terminate
      as of the date such litigation is filed.

   4. Redistribution. You may reproduce and distribute copies of the
      Work or Derivative Works thereof in any medium, with or without
      modifications, and in Source or Object form, provided that You
      meet the following conditions:

      (a) You must give any other recipients of the Work or
          Derivative Works a copy of this License; and

      (b) You must cause any modified files to carry prominent notices
          stating that You changed the files; and

      (c) You must retain, in the Source form of any Derivative Works
          that You distribute, all copyright, patent, trademark, and
          attribution notices from the Source form of the Work,
          excluding those notices that do not pertain to any part of
          the Derivative Works; and

      (d) If the Work includes a "NOTICE" text file as part of its
          distribution, then any Derivative Works that You distribute must
          include a readable copy of the attribution notices contained
          within such NOTICE file, excluding those notices that do not
          pertain to any part of the Derivative Works, in at least one
          of the following places: within a NOTICE text file distributed
          as part of the Derivative Works; within the Source form or
          documentation, if provided along with the Derivative Works; or,
          within a display generated by the Derivative Works, if and
          wherever such third-party notices normally appear. The contents
          of the NOTICE file are for informational purposes only and
          do not modify the License. You may add Your own attribution
          notices within Derivative Works that You distribute, alongside
          or as an addendum to the NOTICE text from the Work, provided
          that such additional attribution notices cannot be construed
          as modifying the License.

      You may add Your own copyright statement to Your modifications and
      may provide additional or different license terms and conditions
      for use, reproduction, or distribution of Your modifications, or
      for any such Derivative Works as a whole, provided Your use,
      reproduction, and distribution of the Work otherwise complies with
      the conditions stated in this License.

   5. Submission of Contributions. Unless You explicitly state otherwise,
      any Contribution intentionally submitted for inclusion in the Work
      by You to the Licensor shall be under the terms and conditions of
      this License, without any additional terms or conditions.
      Notwithstanding the above, nothing herein shall supersede or modify
      the terms of any separate license agreement you may have executed
      with Licensor regarding such Contributions.

   6. Trademarks. This License does not grant permission to use the trade
      names, trademarks, service marks, or product names of the Licensor,
      except as required for reasonable and customary use in describing the
      origin of the Work and reproducing the content of the NOTICE file.

   7. Disclaimer of Warranty. Unless required by applicable law or
      agreed to in writing, Licensor provides the Work (and each
      Contributor provides its Contributions) on an "AS IS" BASIS,
      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
      implied, including, without limitation, any warranties or conditions
      of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
      PARTICULAR PURPOSE. You are solely responsible for determining the
      appropriateness of using or redistributing the Work and assume any
      risks associated with Your exercise of permissions under this License.

   8. Limitation of Liability. In no event and under no legal theory,
      whether in tort (including negligence), contract, or otherwise,
      unless required by applicable law (such as deliberate and grossly
      negligent acts) or agreed to in writing, shall any Contributor be
      liable to You for damages, including any direct, indirect, special,
      incidental, or consequential damages of any character arising as a
      result of this License or out of the use or inability to use the
      Work (including but not limited to damages for loss of goodwill,
      work stoppage, computer failure or malfunction, or any and all
      other commercial damages or losses), even if such Contributor
      has been advised of the possibility of such damages.

   9. Accepting Warranty or Additional Liability. While redistributing
      the Work or Derivative Works thereof, You may choose to offer,
      and charge a fee for, acceptance of support, warranty, indemnity,
      or other liability obligations and/or rights consistent with this
      License. However, in accepting such obligations, You may act only
      on Your own behalf and on Your sole responsibility, not on behalf
      of any other Contributor, and only if You agree to indemnify,
      defend, and hold each Contributor harmless for any liability
      incurred by, or claims asserted against, such Contributor by reason
      of your accepting any such warranty or additional liability.

   END OF TERMS AND CONDITIONS

   APPENDIX: How to apply the Apache License to your work.

      To apply the Apache License to your work, attach the following
      boilerplate notice, with the fields enclosed by brackets "[]"
      replaced with your own identifying information. (Don't include
      the brackets!)  The text should be enclosed in the appropriate
      comment syntax for the file format. We also recommend that a
      file or class name and description of purpose be included on the
      same "printed page" as the copyright notice for easier
      identification within third-party archives.

   Copyright [yyyy] [name of copyright owner]

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
