resource_group_name  = "kvapp1027stage"
location             = "eastus"
storage_account_name = "joreynes1027stage"
virtual_network_name = "myvnet"
subnet_name          = "appservice"

app_service_plans = {
  asp1 = {
    name                         = "functionapp"
    kind                         = "FunctionApp"
    reserved                     = false
    per_site_scaling             = null
    maximum_elastic_worker_count = 20
    sku_tier                     = "ElasticPremium"
    sku_size                     = "EP1"
    sku_capacity                 = 3
  }
}

function_apps = {
  fa1 = {
    name                 = "mykvapp1027stage"
    app_service_plan_key = "asp1"
    app_settings = {
      "FUNCTIONS_WORKER_RUNTIME"         = "powershell"
      "FUNCTIONS_EXTENSION_VERSION"      = "~3"
      "FUNCTIONS_WORKER_RUNTIME_VERSION" = "~7"
    }
    storage_account_name    = "joreynes1027stage"
    os_type                 = null
    client_affinity_enabled = null
    enabled                 = null
    https_only              = null
    assign_identity         = "SystemAssigned, UserAssigned"
    user_ids                = ["/subscriptions/d8656ecf-9955-40f8-9561-adc129f66e3c/resourceGroups/user_defined/providers/Microsoft.ManagedIdentity/userAssignedIdentities/simulation_a"]
    auth_settings           = null
    connection_strings      = null
    version                 = "~3"
    site_config             = null
    enable_monitoring       = false
  }
}

vnet_swift_connection = {
  connection1 = {
    function_app_key = "fa1"
    subnet_name      = "appservice"
    vnet_name        = "myvnet"
  }
}

# application_insights_name = "appinsights10022020"

function_app_additional_tags = {
  iac                   = "Terraform"
  env                   = "UAT"
  trafficmanager_enable = true
  pe_enable             = true
}