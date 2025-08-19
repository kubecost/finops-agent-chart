# IBM FinOps Agent Helm Chart

This repository contains the Helm chart for the IBM FinOps Agent.

## Using the FinOps Agent

The unified FinOps Agent is a single agent that can be used to collect Kubernetes metrics and send it to multiple destinations.

### Supported Destinations

- [Cloudability](https://www.cloudability.com/)
- [Kubecost](https://www.kubecost.com/)

### Considerations when using with Kubecost

The FinOps Agent can be installed independently of the Kubecost Primary. This allows for globally consistent agent configuration across all clusters.

There are two methods to install the FinOps Agent with Kubecost:

1. Install the FinOps Agent as a standalone agent using this Helm chart.
2. Install the FinOps Agent as with the Kubecost Helm chart <https://github.com/kubecost/kubecost/>.

Both methods will deploy the same underlying container.

TODO: Add details on the differences between the two methods.

## Installing the FinOps Agent

Follow the instructions in the chart's [README](charts/finops-agent/README.md) to install the FinOps Agent using this Helm chart.

## License

This project is licensed under the Apache License 2.0. See the [LICENSE](LICENSE) file for details.
