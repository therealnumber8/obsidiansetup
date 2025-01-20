---
created: 2024-11-28T14:36
updated: 2024-12-31T09:40
---
### Databricks setup overview
- **Workspace Creation**: Fill in subscription, resource group, workspace name, region, and pricing tier. -> **Deploy the workspace**
- **Identity and Access Management (IAM)**: Integrate with Azure Active Directory, assign user roles and permissions. -> **Configure user access**
- **Storage Setup**: Configure default storage account access, set up necessary permissions for data sources. -> **Ensure storage access**
- **Unity Catalog Setup**: Create a metastore, define storage credentials, specify **external locations**, organize data assets into catalogs and schemas, assign permissions. -> **Implement data governance with Unity Catalog**
- **Cluster Configuration**: Provide cluster name, select cluster mode, runtime version, node types, and autoscaling settings. -> **Create and launch a cluster**
- **Compliance and Security**: Accept terms and conditions, ensure network security settings allow Databricks to function properly. -> **Finalize compliance and security settings**

### Terms
- **Azure Databricks Workspace**: The top-level environment where users interact with Databricks services. It connects to Unity Catalog for data governance.
- **Unity Catalog**: Integrated within the workspace to provide unified governance across all data assets. This is databricks' unified data governance solution for all data assets, including files, tables, and machine learning models. Its a centralized platform for managing and securing data, enabling fine-grained access control, auditing, and data lineage. It Encompasses the entire data governance framework across all Databricks workspaces in an organization.
- **Pricing Tier:** Choose between Standard, Premium, or Trial (the Premium tier is required for some advanced features like Unity Catalog).
- **Catalog**: Containers within the metastore which is within the unity catalog. A Catalog is just a container that groups related schemas and data assets.
- **Container**: Refers to an organizational unit or a logical grouping mechanism. Not a storage account container.
- **Metastore**: The top-level container within Unity Catalog. It serves as the centralized governance layer that holds all catalogs, schemas, data assets, and associated security configurations.
- **Schemas**: Containers within catalogs that hold tables, views, and other data objects. Schemas are nested within Catalogs. Offer a logical grouping of Data Assets within a Catalog, similar to databases containing tables.
- **Storage Credentials**: Secure credentials (e.g., Azure Service Principal) used to access external storage accounts.
- **External Locations**: Mappings to cloud storage paths (e.g., Azure Blob Storage or ADLS Gen2) managed by Unity Catalog.
- **UCX Migration Tool**: A command-line utility provided by Databricks to help organizations migrate existing Hive metastore tables and associated permissions to Unity Catalog. It automates the process of moving table definitions, access controls, and metadata while preserving data lineage and security configurations. The tool performs validation checks, generates detailed reports, and supports both full and incremental migrations to ensure a smooth transition to Unity Catalog.
- **Metastore:** centralized repository that stores metadata about Apache Hive objects and other data assets. It originated from Apache Hive (hence the name), which is a data warehouse software project built on top of Apache Hadoop.Its an inventory system that keeps track of table definetions and locatins (where the actual data lies), Database/schema definitions etc.
- **External Metastore**: A Hive metastore that exists outside of Databricks, typically used in legacy or hybrid architectures. It stores metadata about tables, partitions, columns, and other database objects in a relational database (usually MySQL or PostgreSQL). Organizations often need to migrate from external metastores to Unity Catalog to take advantage of enhanced security features, centralized governance, and improved data discovery capabilities. The external metastore can continue to operate alongside Unity Catalog during migration to ensure business continuity.
- **Data Assets**: Actual data entities like tables, views, files, and ML models. Data Assets reside within Schemas.
- **Permissions**: Access controls are applied at the Catalog and Schema levels, specifying which users or groups have access to the data assets within.
- **Data Governance**: Encompasses the policies and controls implemented at various levels to ensure data security, compliance, and proper management.

```python
Azure Databricks Workspace
│
└── Unity Catalog
    │
    └── Metastore (Top-level Container)
        │
        ├── Storage Credentials
        │   └── Used by External Locations
        │
        ├── External Locations
        │   └── Map to Cloud Storage Paths
        │
        ├── Catalogs (Containers within the Metastore)
        │   ├── Catalog: Sales_Catalog
        │   │
        │   ├── Schemas (Containers within Catalogs)
        │   │   ├── Schema: Transactions_Schema
        │   │   │   ├── Data Asset: Table - Orders
        │   │   │   └── Data Asset: View - Monthly_Sales
        │   │   ├── Schema: Customers_Schema
        │   │   │   ├── Data Asset: Table - Customer_Info
        │   │   │   └── Data Asset: Model - Customer_Churn_Prediction
        │   │
        │   └── Permissions
        │       └── Users/Groups with access to Sales_Catalog and its Schemas
        │
        ├── Catalog: Marketing_Catalog
        │   │
        │   ├── Schemas
        │   │   ├── Schema: Campaigns_Schema
        │   │   │   └── Data Asset: Table - Campaign_Results
        │   │   ├── Schema: Leads_Schema
        │   │   │   └── Data Asset: Table - Lead_Scoring
        │   │
        │   └── Permissions
        │       └── Users/Groups with access to Marketing_Catalog and its Schemas
        │
        └── Data Governance
            └── Policies and controls applied at all levels
```

### Azure Databricks Workspace Setup
- **Subscription**: The Azure account under which all resources are billed.
- **Resource Group**: A container that holds related resources for an Azure solution.
- **Workspace Name**: A unique identifier for the Databricks workspace.
- **Deploy the Workspace**: The action of creating and provisioning the workspace with the above configurations.

### dentity and Access Management (IAM)
- **Azure Active Directory (AAD)**: Centralized identity provider for authentication and authorization.
- **User Roles**: Predefined roles that determine the level of access (e.g., Workspace Admin, User).
- **Permissions**: Specific rights assigned to users or groups (e.g., read, write, execute).
- **Configure User Access**: Assigning roles and permissions to users/groups within the workspace to control access.

### Storage Setup
- **Default Storage Account Access**: Configuration of the primary storage for the workspace (e.g., Azure Blob Storage, ADLS Gen2).
- **Data Sources**: External repositories where data is stored (e.g., databases, data lakes).
- **Ensure Storage Access**: Setting up connectivity and permissions so the workspace can interact with data sources.

### Unity Catalog: Data Governance and Organization
- **Metastore**: The top-level container that holds all catalogs and data assets within Unity Catalog.
- **Storage Credentials**: Secure credentials (e.g., Azure Service Principal) used to access external storage accounts.
- **External Locations**: Mappings to cloud storage paths managed by Unity Catalog.
- **Catalogs**: Organizational units within the metastore, grouping related schemas.
- **Schemas**: Containers within catalogs that hold tables, views, and other data objects.
- **Data Assets**: Actual data entities like tables, views, files, and machine learning models.
- **Assign Permissions**: Granting access rights to users/groups for catalogs, schemas, and data assets.
- **Implement Data Governance**: Applying policies and controls to manage data access, compliance, and auditing.
### Cluster Configuration: Compute Resources for Data Processing
- **Cluster Name**  Identifier for the compute cluster.
- **Cluster Mode**: Determines how the cluster operates (e.g., Standard, High Concurrency).
- **Runtime Version**: The version of Databricks Runtime (includes Apache Spark and libraries).
- **Node Types**: The Azure VM sizes used for driver and worker nodes.
- **Autoscaling Settings**: Configurations for dynamically adjusting the number of worker nodes based on workload.
- **Create and Launch a Cluster**: Provisioning compute resources according to the specified configurations.

