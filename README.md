# json-schema

This repository contains JSON schemas for CRDs commonly used in Giant Swarm clusters.

It is for example used by `kubeconform` in the [giantswarm/gitops-template](https://github.com/giantswarm/gitops-template)
repository to validate the resources generated and stored in the repository.

## How to regenerate the index

Connect to a Giant Swarm management cluster and run the following commands.

```bash
rm -rf master && mkdir master

kubectl get crd | grep "giantswarm\|flux" | cut -d " " -f1 | xargs -I '{}' sh -c "kubectl get crd '{}' -o jsonpath='{.spec.versions[0].schema.openAPIV3Schema}' | jq > './master/{}'.json"
```
