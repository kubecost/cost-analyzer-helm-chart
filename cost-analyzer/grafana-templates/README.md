# Kubecost Grafana Dashboards

## Overview

Kubecost, by default, ships with a Grafana instance that already contains the dashboards in this repo.

The dashboards in this repo are templated for those wanting to load the dashboards into an existing Grafana instance.

## Caveats

Note that the only method to get accurate costs (reconciled with cloud provider billing) is to use the Kubecost API. Prometheus contains real-time metrics that can only estimate costs using custom pricing or onDemand cloud provider rates.

The primary purpose of the dashboards provided is to allow visibility into the metrics used by Kubecost to create the cost-model.

The networkCosts-metrics dashboard requires the optional networkCosts daemonset to be [enabled](https://docs.kubecost.com/install-and-configure/advanced-configuration/network-costs-configuration).

## Additional Information

Kubecost Grafana [Configuration Guide](https://docs.kubecost.com/install-and-configure/install/custom-grafana)