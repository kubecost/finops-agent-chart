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
2. Install the FinOps Agent with the Kubecost Helm chart <https://github.com/kubecost/kubecost/>.

Both methods will deploy the same underlying container.

## Installing the FinOps Agent



## Advanced Configuration

### Disabling Kubecost Data Collection

By default, the FinOps Agent automatically enables Kubecost data collection when `global.federatedStorage` is configured. To disable Kubecost while keeping the agent running (e.g., for Cloudability-only deployments), use the following advanced override flags:

```yaml
support:
  kubecostEmitterEnabled: "disabled"
  opencostSourceEnabled: "disabled"
```

**Note:** These are advanced override flags. Setting them to any value other than `"disabled"` will force-enable the respective emitter. Omitting these parameters allows the agent to automatically determine enablement based on `global.federatedStorage` configuration.

**Use cases for these flags:**
- Cloudability-only deployments
- Troubleshooting data pipeline issues
- Migration scenarios requiring gradual enablement/disablement
- Cost optimization when Kubecost data is not needed

Follow the instructions in the chart's [README](charts/finops-agent/README.md) to install the FinOps Agent using this Helm chart.

## License

This project is licensed under the Apache License 2.0. See the [LICENSE](LICENSE) file for details.
