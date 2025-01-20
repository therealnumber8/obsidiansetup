---
created: 2024-12-01T15:15
updated: 2024-12-01T15:31
---

### CICD flow
- The script is a single PowerShell script designed to handle both pre-deployment and post-deployment tasks in the CI/CD process for Azure Data Factory.
```bash
Developer commits code changes
   ⬇️
   
CI pipeline is triggered (build)
   ⬇️
   
ARM templates are generated from ADF code
   ⬇️
   
Artifacts are published (ARM templates)
   ⬇️
   
CD pipeline is triggered (release)
   ⬇️
   
Pre-deployment PowerShell script runs (stops triggers)
- Stops modified triggers in the target ADF instance 
- Prepares the environment for deployment
   ⬇️
   
ARM templates are deployed to target environment
   ⬇️
   
Post-deployment PowerShell script runs (starts triggers, cleans up)
- Restarts the triggers that were stopped
- Deletes resources removed from the deployment
- Optionally deletes the deployment history from ARM
   ⬇️
   
Deployment completes successfully
```