resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "this" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# -----------------------------------------------------------------------------
# - Server Package
# -
resource "azurerm_storage_container" "deployments" {
  name                  = "function-releases"
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}

# resource "azurerm_storage_blob" "appcode" {
#     name = "functionapp.zip"
#     storage_account_name = azurerm_storage_account.this.name
#     storage_container_name = azurerm_storage_container.deployments.name
#     type = "block"
#     source = var.functionapp
# }
# -----------------------------------------------------------------------------
resource "azurerm_virtual_network" "this" {
  name                = var.virtual_network_name
  address_space       = ["10.0.0.0/16"]
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
}

resource "azurerm_subnet" "this" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.1.0/24"]

  delegation {
    name = var.subnet_name

    service_delegation {
      name = "Microsoft.Web/serverFarms"
    }
  }
}

# TODO keeping data references in case the resources need to be managed
# outside of this state
data "azurerm_resource_group" "this" {
  # count = local.resourcegroup_state_exists == false ? 1 : 0
  name = azurerm_resource_group.this.name
}

data "azurerm_storage_account" "this" {
  # for_each            = local.storage_state_exists == false ? var.function_apps : {}
  # name                = each.value.storage_account_name
  # resource_group_name = local.resourcegroup_state_exists == true ? var.resource_group_name : data.azurerm_resource_group.this.0.name

  name                = azurerm_storage_account.this.name
  resource_group_name = azurerm_resource_group.this.name

}

# data "azurerm_application_insights" "this" {
#   count               = (local.appinsights_state_exists == false && var.application_insights_name != null) ? 1 : 0
#   name                = var.application_insights_name
#   resource_group_name = local.resourcegroup_state_exists == true ? var.resource_group_name : data.azurerm_resource_group.this.0.name
# }

# locals {
#   tags                       = merge(var.function_app_additional_tags, (local.resourcegroup_state_exists == true ? lookup(data.terraform_remote_state.resourcegroup.outputs.resource_group_tags_map, var.resource_group_name) : data.azurerm_resource_group.this.0.tags))
#   resourcegroup_state_exists = length(values(data.terraform_remote_state.resourcegroup.outputs)) == 0 ? false : true
#   storage_state_exists       = length(values(data.terraform_remote_state.storage.outputs)) == 0 ? false : true
#   appinsights_state_exists   = length(values(data.terraform_remote_state.applicationinsights.outputs)) == 0 ? false : true

#   application_insights_settings = {
#     "APPINSIGHTS_INSTRUMENTATIONKEY" = var.application_insights_name != null ? (local.appinsights_state_exists == true ? lookup(data.terraform_remote_state.applicationinsights.outputs.instrumentation_key_map, var.application_insights_name, null) : data.azurerm_application_insights.this.0.instrumentation_key) : null
#   }
# }

# if using msi, these can be set via a post action https://github.com/marketplace/actions/azure-functions-action
# locals {
#   app_settings_dynamic = {
#     HASH                     = base64encode(filesha256(var.functionapp))
#     WEBSITE_RUN_FROM_PACKAGE = format("https://%s.blob.core.windows.net/%s/%s%s", azurerm_storage_account.this.name, azurerm_storage_container.deployments.name, azurerm_storage_blob.appcode.name, data.azurerm_storage_account_sas.this.sas)
#   }
# }

# resource "azurerm_app_service" "this" {
#   for_each            = var.app_service_plans
#   name                = "example-app-service"
#   location            = azurerm_resource_group.this.location
#   resource_group_name = azurerm_resource_group.this.name
#   app_service_plan_id = azurerm_app_service_plan.example.id
# }

# -
# - App Service Plan
# -
resource "azurerm_app_service_plan" "this" {
  for_each            = var.app_service_plans
  name                = each.value["name"]
  resource_group_name = azurerm_resource_group.this.name
  # resource_group_name = local.resourcegroup_state_exists == true ? var.resource_group_name : data.azurerm_resource_group.this.0.name
  location = var.location
  # location            = local.resourcegroup_state_exists == true ? lookup(data.terraform_remote_state.resourcegroup.outputs.resource_group_locations_map, var.resource_group_name) : data.azurerm_resource_group.this.0.location

  kind                         = coalesce(lookup(each.value, "kind"), "FunctionApp")
  maximum_elastic_worker_count = lookup(each.value, "maximum_elastic_worker_count", null)
  reserved                     = coalesce(lookup(each.value, "kind"), "FunctionApp") == "Linux" ? true : coalesce(lookup(each.value, "reserved"), false)
  per_site_scaling             = coalesce(lookup(each.value, "per_site_scaling"), false)

  sku {
    tier     = coalesce(each.value["sku_tier"], "Dynamic")
    size     = coalesce(each.value["sku_size"], "Y1")
    capacity = lookup(each.value, "sku_capacity", null)
  }

  lifecycle {
    ignore_changes = [kind, is_xenon]
  }

  # tags = local.tags
  tags = var.function_app_additional_tags
}

# -
# - Azure Function App
# -
resource "azurerm_function_app" "this" {
  for_each = var.function_apps
  name     = each.value["name"]
  location = var.location
  # location                   = local.resourcegroup_state_exists == true ? lookup(data.terraform_remote_state.resourcegroup.outputs.resource_group_locations_map, var.resource_group_name) : data.azurerm_resource_group.this.0.location
  # resource_group_name        = local.resourcegroup_state_exists == true ? var.resource_group_name : data.azurerm_resource_group.this.0.name
  resource_group_name        = azurerm_resource_group.this.name
  app_service_plan_id        = lookup(azurerm_app_service_plan.this, each.value["app_service_plan_key"])["id"]
  storage_account_name       = each.value["storage_account_name"]
  storage_account_access_key = azurerm_storage_account.this.primary_access_key
  # storage_account_access_key = local.storage_state_exists == true ? lookup(data.terraform_remote_state.storage.outputs.primary_access_keys_map, each.value["storage_account_name"]) : lookup(data.azurerm_storage_account.this, each.key)["primary_access_key"]

  # app_settings            = each.value.enable_monitoring == true ? merge(local.application_insights_settings, lookup(each.value, "app_settings", {})) : lookup(each.value, "app_settings", {})
  app_settings            = lookup(each.value, "app_settings", {})
  enabled                 = coalesce(each.value.enabled, true)
  os_type                 = lookup(each.value, "os_type", null)
  version                 = lookup(each.value, "version", null)
  https_only              = lookup(each.value, "https_only", null)
  client_affinity_enabled = lookup(each.value, "client_affinity_enabled", null)

  dynamic "auth_settings" {
    for_each = lookup(each.value, "auth_settings", null) == null ? [] : list(lookup(each.value, "auth_settings"))
    content {
      enabled                        = coalesce(lookup(auth_settings.value, "enabled"), false)
      additional_login_params        = lookup(auth_settings.value, "additional_login_params", null)
      allowed_external_redirect_urls = lookup(auth_settings.value, "allowed_external_redirect_urls", null)
      default_provider               = lookup(auth_settings.value, "default_provider", null)
      issuer                         = lookup(auth_settings.value, "issuer", null)
      runtime_version                = lookup(auth_settings.value, "runtime_version", null)
      token_refresh_extension_hours  = lookup(auth_settings.value, "token_refresh_extension_hours", null)
      token_store_enabled            = lookup(auth_settings.value, "token_store_enabled", null)
      unauthenticated_client_action  = lookup(auth_settings.value, "unauthenticated_client_action", null)

      dynamic "active_directory" {
        for_each = lookup(auth_settings.value, "active_directory", null) == null ? [] : list(lookup(auth_settings.value, "active_directory"))
        content {
          client_id         = active_directory.value.client_id
          client_secret     = lookup(active_directory.value, "client_secret", null)
          allowed_audiences = lookup(active_directory.value, "allowed_audiences", null)
        }
      }

      dynamic "microsoft" {
        for_each = lookup(auth_settings.value, "microsoft", null) == null ? [] : list(lookup(auth_settings.value, "microsoft"))
        content {
          client_id     = microsoft.value.client_id
          client_secret = microsoft.value.client_secret
          oauth_scopes  = lookup(microsoft.value, "oauth_scopes", null)
        }
      }
    }
  }

  dynamic "connection_string" {
    for_each = coalesce(lookup(each.value, "connection_strings"), [])
    content {
      name  = connection_string.value.name
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }

  dynamic "site_config" {
    for_each = lookup(each.value, "site_config", null) == null ? [] : list(lookup(each.value, "site_config"))
    content {
      always_on          = lookup(merge(azurerm_app_service_plan.this, data.azurerm_app_service_plan.this), each.value["app_service_plan_key"]).sku[0].tier == "Dynamic" ? false : true
      ftps_state         = lookup(site_config.value, "ftps_state", null)
      http2_enabled      = lookup(site_config.value, "http2_enabled", null)
      linux_fx_version   = lookup(site_config.value, "linux_fx_version", null) == null ? null : lookup(site_config.value, "linux_fx_version_local_file_path", null) == null ? lookup(site_config.value, "linux_fx_version", null) : "${lookup(site_config.value, "linux_fx_version", null)}|${filebase64(lookup(site_config.value, "linux_fx_version_local_file_path", null))}" #(Optional) Linux App Framework and version for the App Service. Possible options are a Docker container (DOCKER|<user/image:tag>), a base-64 encoded Docker Compose file (COMPOSE|${filebase64("compose.yml")}) or a base-64 encoded Kubernetes Manifest (KUBE|${filebase64("kubernetes.yml")}).
      min_tls_version    = lookup(site_config.value, "min_tls_version", null)                                                                                                                                                                                                                                                                                                   #(Optional) The minimum supported TLS version for the app service. Possible values are 1.0, 1.1, and 1.2. Defaults to 1.2 for new app services.
      websockets_enabled = lookup(site_config.value, "websockets_enabled", null)                                                                                                                                                                                                                                                                                                #(Optional) Should WebSockets be enabled?

      dynamic "ip_restriction" {
        for_each = coalesce(lookup(site_config.value, "ip_restrictions"), [])
        content {
          ip_address = lookup(ip_restriction.value, "subnet_name", null) == null ? ip_restriction.value["ip_address"] : null
          subnet_id  = azurerm_subnet.this.id
          # subnet_id  = lookup(ip_restriction.value, "ip_address", null) == null ? lookup(data.terraform_remote_state.networking.outputs.map_subnet_ids, ip_restriction.value["subnet_name"]) : null
        }
      }

      dynamic "cors" {
        for_each = lookup(site_config.value, "cors", null) == null ? [] : list(lookup(site_config.value, "cors"))
        content {
          allowed_origins     = lookup(cors.value, "allowed_origins", null)
          support_credentials = lookup(cors.value, "support_credentials", null)
        }
      }
    }
  }

  dynamic "identity" {
    for_each = coalesce(lookup(each.value, "assign_identity"), false) == true ? list(lookup(each.value, "assign_identity", false)) : []
    content {
      type         = lookup(each.value, "assign_identity", null)
      identity_ids = lookup(each.value, "user_ids", null)
    }
  }

  lifecycle {
    ignore_changes = [
      app_settings.WEBSITE_RUN_FROM_ZIP,
      app_settings.WEBSITE_RUN_FROM_PACKAGE,
      app_settings.MACHINEKEY_DecryptionKey,
    ]
  }

  # tags = local.tags
  tags = var.function_app_additional_tags
}


# - 
# - Manage Azure Function Virtual Network Association 
# -
resource "azurerm_app_service_virtual_network_swift_connection" "this" {
  for_each       = var.vnet_swift_connection
  app_service_id = lookup(azurerm_function_app.this, each.value.function_app_key)["id"]
  # subnet_id      = local.networking_state_exists == true ? lookup(data.terraform_remote_state.networking.outputs.map_subnet_ids, each.value.subnet_name) : lookup(data.azurerm_subnet.this, each.key)["id"]
  subnet_id = azurerm_subnet.this.id
}