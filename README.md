## FinOps Agent

The IBM FinOps Agent collects usage and cost data from items running in the kubernetes cluster. These can then be consumed by Cloudability(TM) and Kubecost(TM).

## Maintainers

**IBM, Inc. All Rights Reserved.**  
[https://ibm.com](https://ibm.com)

## Usage

[Helm](https://helm.sh/) must be installed to use the charts. Please refer to Helm's [documentation](https://helm.sh/docs/) to get started.

Once Helm is set up properly, add the repo as follows:

```bash
helm repo add finops-agent https://kubecost.github.io/finops-agent-chart
```

## Licensing

Licensed under the Apache License, Version 2.0 (the "License")