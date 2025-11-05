Awesome—let’s implement the centralized (best-practice) route step-by-step with Terraform.

# 0) What you’re building

* Every prod subscription streams its Activity Log → one Log Analytics Workspace (LAW). ([Microsoft Learn][1])
* One Scheduled Query (v2) alert on that LAW fires on any successful “Delete” operation. ([Microsoft Learn][2])
* Action Group(s) deliver notifications; optional Alert Processing Rules handle routing/suppression. ([Terraform Registry][3])

# 1) Create the shared workspace + action group (central subscription)

```hcl
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "mon" {
  name     = "rg-monitoring"
  location = var.location
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-central-monitoring"
  location            = azurerm_resource_group.mon.location
  resource_group_name = azurerm_resource_group.mon.name
  sku                 = "PerGB2018"
  retention_in_days   = 90
}

resource "azurerm_monitor_action_group" "oncall" {
  name                = "ag-prod-delete"
  resource_group_name = azurerm_resource_group.mon.name
  short_name          = "prod-del"
  email_receiver {
    name          = "oncall"
    email_address = var.oncall_email
  }
  # add webhook/Teams/Slack as needed
}
```

LAW is the hub for cross-subscription log alerts; Action Groups are how alerts notify people/systems. ([Microsoft Learn][2])

# 2) Stream Activity Logs from every prod subscription → LAW

Option A (policy at scale, recommended): Assign built-in policies/initiatives that auto-deploy diagnostic settings to stream Activity Logs to your LAW (works tenant-wide / MG-wide). ([Microsoft Learn][4])

Option B (Terraform loop): Create a diagnostic setting at the subscription scope per prod subscription.

```hcl
# One provider alias per subscription you’ll touch
provider "azurerm" {
  alias           = "sub"
  features        = {}
  subscription_id = var.current_sub_id
}

# Map of prod subscription IDs -> display names (or empty string)
variable "prod_subscription_ids" { type = list(string) }

# For each subscription, attach a diagnostic setting that sends Activity Log → LAW
resource "azurerm_monitor_diagnostic_setting" "sub_activity_to_law" {
  for_each                   = toset(var.prod_subscription_ids)
  name                       = "activity-to-central-law"
  # subscription resource ID
  target_resource_id         = "/subscriptions/${each.key}"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  log { category = "Administrative" enabled = true }
  log { category = "ServiceHealth"  enabled = true }
  log { category = "ResourceHealth" enabled = true }
  log { category = "Alert"          enabled = true }
  log { category = "Autoscale"      enabled = true }
}
```

Subscription-level diagnostic settings are the supported way to export the Activity Log; Terraform uses `azurerm_monitor_diagnostic_setting`. ([Microsoft Learn][1])

Tip: Doing this with Azure Policy is cleaner for scale; there are built-ins specifically for the Activity Log→LAW path. ([Microsoft Learn][4])

# 3) Create one KQL log alert (Scheduled Query v2) on the workspace

```hcl
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "prod_deletes" {
  name                = "alert-prod-resource-deletes"
  location            = azurerm_resource_group.mon.location
  resource_group_name = azurerm_resource_group.mon.name
  scopes              = [azurerm_log_analytics_workspace.law.id]

  description          = "Pages on any successful Delete operation across prod subscriptions"
  severity             = 2
  enabled              = true
  window_duration      = "PT5M"
  evaluation_frequency = "PT5M"
  auto_mitigation_enabled = false

  # Count any matching deletes > 0 in the last 5 minutes
  criteria {
    query = <<KQL
AzureActivity
| where CategoryValue == "Administrative"
| where ActivityStatusValue == "Succeeded"
| where OperationNameValue has "Delete"
| project TimeGenerated, OperationNameValue, ActivityStatusValue, Caller, ResourceGroup, _SubscriptionId = SubscriptionId, ResourceId
    KQL
    time_aggregation = "Count"
    operator         = "GreaterThan"
    threshold        = 0
  }

  action {
    action_groups = [azurerm_monitor_action_group.oncall.id]
  }
}
```

Why these columns: `AzureActivity` is the Activity Log in LAW; `OperationNameValue` carries normalized operation IDs (e.g., `Microsoft.Resources/subscriptions/resourcegroups/delete`), and `ActivityStatusValue == "Succeeded"` avoids noise from failed attempts. ([Microsoft Learn][5])

# 4) (Optional) Filter to “prod only”

If all prod resources are in ~10 prod subscriptions, filter by those subscription IDs:

```kql
| where SubscriptionId in~ ( "sub-aaa...", "sub-bbb...", "sub-ccc..." )
```

If you must use `tags['prod']=true`, note: tags aren’t on AzureActivity rows. You’d enrich by joining to an inventory (e.g., a daily export into LAW) or rely on the subscription filter (simpler and robust). ([Microsoft Learn][5])

# 5) (Optional) Alert Processing Rules

Use processing rules to suppress during maintenance windows or to add/remove action groups centrally—handy when teams rotate on-call. Terraform has resources for them too. ([Microsoft Learn][6])

# 6) Test it

* Manually delete a test resource group in a sandbox prod sub (or create a dummy object, then delete).
* In LAW, run the same KQL to confirm the row appears.
* Ensure the alert fires and your Action Group receives notifications. Azure docs confirm activity log export/diagnostic setting pipeline and AzureActivity field names. ([Microsoft Learn][1])

# Notes & pitfalls

* Central LAW works across subscriptions/regions as long as diagnostic settings point there. ([Microsoft Learn][1])
* Use Azure Policy to ensure every (new) prod subscription auto-streams its Activity Log—this closes human gaps. ([Microsoft Learn][4])
* Prefer `OperationNameValue` over `OperationName` for reliable matching. ([Microsoft Learn][5])
* Keep Action Groups simple; you can layer routing with Alert Processing Rules later. ([Microsoft Learn][6])

Want me to tailor the Terraform to your exact variable style (e.g., a map of sub→alias, Teams webhooks, split-by-SubscriptionId for one alert per sub), or add the Azure Policy assignment to auto-deploy those diagnostic settings?

[1]: https://learn.microsoft.com/en-us/azure/azure-monitor/platform/activity-log?utm_source=chatgpt.com "Activity log in Azure Monitor"
[2]: https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/alerts-overview?utm_source=chatgpt.com "Overview of Azure Monitor alerts"
[3]: https://registry.terraform.io/providers/hashicorp/azurerm/3.31.0/docs/resources/monitor_action_group?utm_source=chatgpt.com "azurerm_monitor_action_group | hashicorp/azurerm | Terraform"
[4]: https://learn.microsoft.com/en-us/azure/azure-monitor/platform/diagnostic-settings-policy-built-in?utm_source=chatgpt.com "Create diagnostic settings at scale using built-in Azure ..."
[5]: https://learn.microsoft.com/en-us/azure/azure-monitor/reference/tables/azureactivity?utm_source=chatgpt.com "Azure Monitor Logs reference - AzureActivity"
[6]: https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/alerts-processing-rules?utm_source=chatgpt.com "Alert processing rules - Azure Monitor"
