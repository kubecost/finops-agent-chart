# Local Testing Guide for FinOps Agent Chart

## Setup
```bash
cd charts/finops-agent
helm dependency build
```

## Testing Commands

### Dry Run (Recommended)
```bash
helm install test-release . --set global.clusterId="test-cluster-id" --dry-run
```

### Template Rendering
```bash
helm template test-release . --set global.clusterId="test-cluster-id"
```

### Lint Check
```bash
helm lint .
```

## Test Scenarios

**Custom image tag:**
```bash
helm install test-release . --set global.clusterId="test" --set image.tag="v1.0.5" --dry-run
```

**With Cloudability:**
```bash
helm install test-release . --set global.clusterId="test" --set agent.cloudability.enabled=true --dry-run
```

**With values file:**
```bash
helm install test-release . --values examples/kubecost/helmValues-kubecost-aws.yaml --dry-run
```

## Notes
- NOTES output (including version warnings) appears at the end of install/upgrade commands
- Use `--dry-run` to test without cluster access
- Run `helm dependency build` if you see missing dependencies error