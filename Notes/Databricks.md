---
created: 2024-08-17T18:08
updated: 2024-12-09T06:31
---
### What is Databricks?
- Databricks was founded by the creators of Apache Spark, which began as a research project at UC Berkeley's AMPLab.
- A Databricks Cluster is really just the implementation of a managed Spark cluster orchestrated on virtual machines provisioned in the cloud or on prem server farm.
- Databricks unifies data engineering, data science, and analytics on a single platform. It acclerates the data-to-insights lifecycle.
- A Databricks Notebook is just a glorified interactive script editor with built-in data visualization capabilities. Databricks Notebooks are analogous to Jupyter Notebooks, providing an interactive environment for writing and executing code.
- Databricks Jobs is just an abstraction over scheduled Spark tasks that utilizes cluster computing resources underneath.
- Databricks is a lakehouse platform
- Databricks isn't a type of database, but Delta Lake is a type of data storage technology used within Databricks.
- **Databricks** is a cloud-based platform designed for big data analytics and artificial intelligence (AI). It provides an integrated environment for data engineering, data science, machine learning, and analytics, built on top of Apache Spark, which is a unified analytics engine for large-scale data processing.
- Amazon EMR (Elastic MapReduce) combined with AWS SageMaker offers similar capabilities to Databricks in the AWS ecosystem.
- It's not strictly a data warehouse, but it can perform similar functions when combined with a data lake. Databricks is an **analytics platform** that specializes in big data processing and machine learning, b*uilt on top of **Apache Spark**. It is often referred to as a **lakehouse platform**, which combines elements of both **data lakes** and **data warehouses**.\
- What tools/technologies/drivers/software does it use to do what it does?:  **Apache Spark**: For distributed data processing. **Delta Lake**: For reliable data storage. **MLflow**: For machine learning lifecycle management. **REST APIs and SDKs**: For programmatic interactions.
- All Databricks clusters are Spark clusters but not all Spark clusters are Databricks clusters.
- All Delta Lake tables are data lake files but not all data lake files are Delta Lake tables.
- All Databricks notebooks are code editors but not all code editors are Databricks notebooks.

### Why Databricks?
1. **Unified Platform**: Databricks offers a collaborative environment for data scientists, engineers, and business analysts to work together efficiently on various stages of data processing, from ingestion and exploration to model building and deployment.

2. **Scalability**: Leveraging the power of Apache Spark, Databricks can handle massive amounts of data and compute operations, scaling easily to meet demand without compromising performance.

3. **Optimized Apache Spark Environment**: Databricks provides a highly optimized version of Apache Spark, ensuring better performance and reliability compared to standard installations.

4. **Delta Lake**: Integrated with Databricks, Delta Lake offers an open-source storage layer that brings reliability to data lakes. It provides ACID transactions, scalable metadata handling, and unifies data processing and machine learning on one system.

5. **MLflow**: Databricks also integrates MLflow, an open-source platform to manage the ML lifecycle, including experimentation, reproducibility, and deployment of ML models.

6. **Collaborative Notebooks**: Similar to Jupyter Notebooks, Databricks offers collaborative notebooks which allow users to write code, document processes, and share insights within the team, all in real-time.

7. **Databricks SQL**: For running SQL queries at scale on your data lake, offering performance optimizations and simple management.

### Use Cases
- **Data Engineering**: Build reliable data pipelines.
- **Data Science**: Experiment with data models interactively.
- **Machine Learning**: Deploy and track ML models in production.
- **Business Analytics**: Visualize data insights and report across teams.




### Databricks cluster modes

| Cluster Mode     | Description                              | Use Cases                                       |
| ---------------- | ---------------------------------------- | ----------------------------------------------- |
| Standard         | Dedicated resources per cluster          | Development, testing, production workloads      |
| High Concurrency | Shared resources with resource isolation | Multi-user scenarios, interactive workloads     |
| Single Node      | All Spark components on a single node    | Lightweight tasks, debugging, local development |
