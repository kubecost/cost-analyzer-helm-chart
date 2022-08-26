Thanks for your interest in Kubecost!  To ensure you get the help you need, please follow these guidelines:

- If you have questions about product functionality/usage or need assistance with product installation/configuration, please email support@kubecost.com, where our support engineering team will be happy to help!
- If you have a reproducible bug or a feature request, you're in the right place.  Please include the information requested below.


---
# For reproducible bugs, please provide the following

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

---
# For feature requests, please provide the following:

**What problem are you trying to solve?**  
A clear and concise description of what the problem is. Ex. I'm always frustrated when [...]

**Describe the solution you'd like**  
A clear and concise description of what you want to happen.

**Describe alternatives you've considered**  
A clear and concise description of any alternative solutions or features you've considered.

**How would users interact with this feature?**
