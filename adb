You’ve got two workable patterns. Since you’re already using per-subscription Activity Log alerts, the cleanest is to keep those rules broad and add Alert Processing Rule suppressions per subscription that target the RGs you want to ignore.

Here’s how to wire it in your current layout.

1. Add a variable listing excluded RGs per subscription



variable "excluded_rgs_by_subscription" {
  description = "Map: subscription key -> list of RG names to suppress notifications for"
  type        = map(list(string))
  default     = {}
}

2. For each subscription alias, create a suppression rule scoped to those RGs
(note: the rule must live in the same subscription as the scopes)



# Example: datacloud-prod-04
resource "azurerm_monitor_alert_processing_rule_suppression" "suppress_rg_deletes_datacloud_prod_04" {
  provider            = azurerm.datacloud-prod-04
  name                = "apr-suppress-activitylog-rgs"
  resource_group_name = azurerm_resource_group.alerts_rg_datacloud_prod_04.name
  location            = "Global"  # APRs are global-scoped resources

  # Suppress alerts for these RGs in this subscription
  scopes = [
    for rg in coalesce(var.excluded_rgs_by_subscription["datacloud-prod-04"], []) :
    "/subscriptions/${local.prod_subscriptions["datacloud-prod-04"].subscription_id}/resourceGroups/${rg}"
  ]

  # Narrow the suppression to Activity Log alerts only (Administrative)
  condition {
    monitor_service {
      operator = "Equals"
      values   = ["ActivityLog Administrative"]
    }
    # Optional: only suppress your "delete" alert rules (match by name fragment)
    # alert_rule_name {
    #   operator = "Contains"
    #   values   = ["delete"]
    # }
    # Optional: limit by severity if you set specific severities on these rules
    # severity {
    #   operator = "Equals"
    #   values   = ["Sev2"]
    # }
  }
}

Repeat that block for each provider alias (actuary-prod-subscription, cloudops-subscription, etc.), swapping the provider, RG, and the map key inside coalesce(...). You’re already creating one rg-log-alerts-<sub> per subscription, so use it to host the suppression rule as shown. Azure requires APR scope to be in the same subscription as the targeted RGs. 

Why suppression here?

You can’t express “exclude RGs” directly in the Activity Log alert; it only supports inclusive filters (e.g., resource_groups list). APRs are designed to suppress notifications by scope (RGs) without touching the alert itself. 


Optional alternative (include-only): if your “allowed” RG list is small and stable, push it into the alert criteria

resource "azurerm_monitor_activity_log_alert" "this" {
  # ...
  criteria {
    category       = var.category
    operation_name = var.operation_name
    level          = var.level
    # include-only (mutually exclusive with resource_group): list of RG names
    resource_groups = var.included_resource_groups
  }
}

Use this only if maintaining an allow-list is easier than an exclude-list. The schema supports resource_groups in criteria. 

Quick checklist

Put one suppression rule per subscription, in that sub’s rg-log-alerts-*. Set location = "Global". 

Scope the rule to the RG resource IDs you want to exclude. 

Filter the rule to monitor_service == "ActivityLog Administrative" so you don’t silence metric/KQL alerts by accident. Optionally filter by alert rule name or severity. 


If you want, paste the subscription keys → RG names you’d like excluded and I’ll drop in the exact for_each blocks for all your provider aliases.