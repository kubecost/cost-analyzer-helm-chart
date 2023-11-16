# Kubecost Helm Chart Development Guide

This guide contains tips on setting up a development environment for the Kubecost Helm chart.

> [!IMPORTANT]  
> Following some of these steps may involve billing charges by GitHub for either an individual account or organization.

## Developing with Codespaces and Devcontainers

GitHub includes a feature called [Codespaces](https://github.com/features/codespaces) which allows you to set up an instant, fully-provisioned development environment in the cloud in seconds. This is a containerized environment powered by [Development Containers](https://containers.dev/) ("devcontainers") which have all the necessary project-specific tools to get started.

This repository contains two such devcontainers to aid in easy development, testing, and contribution. The first, which is the default, contains basic tools such as `helm` and `kubectl` along with some other commonly-used tools for Chart development. This default devcontainer will be the one used if no other selection is chosen. Follow the process [here](https://docs.github.com/en/codespaces/developing-in-a-codespace/creating-a-codespace-for-a-repository#creating-a-codespace-for-a-repository) to create a Codespaces environment using the default devcontainer.

The second devcontainer provides a Docker-in-Docker experience allowing you to test/develop your Helm chart changes as well as deploy them to a running cluster all inside the Codespaces environment. In order to create this more advanced Codespaces environment, follow the guide [here](https://docs.github.com/en/codespaces/developing-in-a-codespace/creating-a-codespace-for-a-repository#creating-a-codespace-for-a-repository) at step four and then select the "Cluster" configuration as shown below. You may also wish to use a larger machine type such as the 4-core option if you intend on actually deploying Kubecost.

![Custom devcontainer profile](/docs/images/custom-devcontainer.png)

This Cluster profile includes Docker and Minikube allowing you to not only develop against the Helm chart but also fully deploy, as opposed to just rendering, the Chart to inspect changes. When running Minikube in this devcontainer, pass the `--force` flag to permit Minikube to run as root.

```sh
minikube start --force
```

For more information on GitHub Codespaces, see the reference documentation [here](https://docs.github.com/en/codespaces/overview).
