# IBM FinOps Agent Helm Chart

A Helm chart for deploying the IBM FinOps Agent on Kubernetes clusters. The agent collects usage and cost data from cluster resources and supports integration with Cloudability™ and Kubecost™.

## Installation

```bash
helm install ibm-finops-agent \
  --repo https://kubecost.github.io/finops-agent-chart finops-agent \
  --set global.clusterId="globally-unique-cluster-id"
```

## Documentation

For complete configuration options, prerequisites, and advanced usage, see the [detailed chart documentation](https://github.com/kubecost/finops-agent-chart/blob/main/charts/finops-agent/README.md).

## Maintainers

**IBM, Inc. All Rights Reserved.**  
[https://ibm.com](https://ibm.com)

## License

Licensed under the Apache License, Version 2.0 (the "License")
