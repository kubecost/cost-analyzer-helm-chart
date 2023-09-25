# Kubecost Grafana Dashboards

## Overview

Kubecost, by default, is bundled with a Grafana instance that already contains the dashboards in this repo.

The dashboards in this repo are templated for those wanting to load the dashboards into an existing Grafana instance.

## Caveats

Note that the only method to get accurate costs (reconciled with cloud provider billing) is to use the Kubecost API. Prometheus contains real-time metrics that can only estimate costs using custom pricing or onDemand cloud provider rates.

The primary purpose of the dashboards provided is to allow visibility into the metrics used by Kubecost to create the cost-model.

The networkCosts-metrics dashboard requires the optional networkCosts daemonset to be [enabled](https://docs.kubecost.com/install-and-configure/advanced-configuration/network-costs-configuration).

## Metrics Required

`kubecost-container-stats` metrics:

```
container_cpu_usage_seconds_total
kube_pod_container_resource_requests
container_memory_working_set_bytes
container_cpu_cfs_throttled_periods_total
container_cpu_cfs_periods_total
```

`network-transfer-data` metrics:

```
kubecost_pod_network_ingress_bytes_total
kubecost_pod_network_egress_bytes_total
```

`disk-usage` metrics:
```
container_fs_limit_bytes
container_fs_usage_bytes
```

## Additional Information

Kubecost Grafana [Configuration Guide](https://docs.kubecost.com/install-and-configure/install/custom-grafana)