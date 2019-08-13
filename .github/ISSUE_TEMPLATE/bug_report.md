---
name: Bug report
about: Create a report to help us improve
title: ''
labels: bug
assignees: ''

---

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. See error

**Expected behavior**
A clear and concise description of what you expected to happen.

**Screenshots**
If applicable, add screenshots to help explain your problem.

**Collect logs (please complete the following information):**

 - Run `helm ls` and paste the output here:

 - If the pod is stuck in init, run `kubectl logs <kubecost-cost-analyzer pod name> -n kubecost -c cost-analyzer-init` and paste output here:

 - If a page is broken or not loading, open your javascript developer console and paste the ouput here:

 - Run `kubectl logs <kubecost-cost-analyzer pod name> -n kubecost -c cost-analyzer-server` and paste the output here:

 - Run `kubectl logs <kubecost-cost-analyzer pod name> -n kubecost -c cost-model` and paste the output here:

 - Run `kubectl logs <kubecost-cost-analyzer pod name> -n kubecost -c cost-analyzer-frontend` and paste the output here:
