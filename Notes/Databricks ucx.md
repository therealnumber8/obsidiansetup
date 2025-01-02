---
created: 2024-12-31T10:03
updated: 2024-12-31T11:25
---
### ucx
- UCX migrates assets from an external Hive metastore to Unity Catalog.
- External Hive Metastore (HMS): This is your existing external metastore where your current databases, tables, and other assets are stored, Not the local/internal metastore that comes with Databricks
- Unity Catalog (UC): Unity Catalog is Databricks' new governance layer, Provides centralized access control and governance at the account levelm Introduces three-level namespace (catalog.schema.table).

- test

### Installation
```bash
# Install Databricks CLI on MacOS
brew install databricks

# Install Databricks CLI on Windows 
winget install databricks

# Login to Databricks CLI
databricks configure --profile PROFILE_NAME
```

### Install UCX globally (recommended)
```bash
databricks labs install ucx
```

### Install UCX for specific user
```bash
databricks labs install ucx --force-install=user
```

### Install UCX for entire account
```bash
databricks labs install ucx --force-install=account
```

### Run initial assessment to inventory all assets
- Assets in Databricks refers to all your workspace resources: **databases, tables, workflows, jobs, notebooks, init scripts, external locations, service principals, mount points, clusters, and any other components** configured in your workspace
- Inventory in Databricks context means creating a comprehensive catalog or list of all existing assets, their configurations, dependencies, and usage patterns within your workspace
- You need to have an external metastore configured and attached to your workspace before running the assessment.
- From the videos, during UCX installation it asks for an "inventory database" (which defaults to 'ucx') - this is where all the assessment results will be stored in your external metastore. The assessment command will: Crawl your workspace assets, Store results in the 'ucx' database in your external metastore, Populate the assessment dashboards using this data
```bash
databricks labs ucx ensure-assessment run
```

### Create account level groups that match workspace groups
```bash
databricks labs ucx create-account-groups --profile PROFILE_NAME --workspace-id WORKSPACE_ID
```

### Group migration core workflow to rename workspace groups and apply permissions
```bash
# Via CLI
databricks labs ucx migrate-groups

# Or use UI workflow: "UCX - Migrate Groups"
```

### Validate group permissions after migration
```bash
# Via CLI
databricks labs ucx validate-group-permissions

# Or use UI workflow: "UCX - Validate Group Permissions" 
```

### Remove workspace local backup groups after successful migration
```bash
# Via CLI
databricks labs ucx remove-workspace-local-backup-groups

# Or use UI workflow: "UCX - Remove Workspace Local Backup Groups"
```

### Check assessment dashboards
Navigate to Dashboards in UI:
- UCX Assessment (main inventory dashboard)
- UCX Assessment Azure (service principals)
- UCX Assessment Interactive (cluster compatibility) 
- UCX Migration Progress
- UCX Estimates

### View workflows in UI
Filter workflows by "UCX" prefix to see all available migration workflows

### View installation configurations
```bash
# Open UCX config file
cat /Applications/ucx/README.md

# View workflows directory
cd /Applications/ucx/workflows
```