output "aks_clusters" {
  value = module.aks_clusters
}

module "aks_clusters" {
  source     = "./modules/compute/aks"
  depends_on = [module.networking, module.routes, module.azurerm_firewall_policies]
  for_each   = local.compute.aks_clusters

  global_settings     = local.global_settings
  client_config       = local.client_config
  diagnostics         = local.combined_diagnostics
  diagnostic_profiles = try(each.value.diagnostic_profiles, {})
  base_tags           = try(local.global_settings.inherit_tags, false) ? local.resource_groups[each.value.resource_group_key].tags : {}
  settings            = each.value
  subnets             = lookup(each.value, "lz_key", null) == null ? local.combined_objects_networking[local.client_config.landingzone_key][each.value.vnet_key].subnets : local.combined_objects_networking[each.value.lz_key][each.value.vnet_key].subnets
  resource_group      = local.resource_groups[each.value.resource_group_key]
  private_dns_zone_id = try(local.combined_objects_private_dns[each.value.private_dns_zone.lz_key][each.value.private_dns_zone.key].id,
    local.combined_objects_private_dns[local.client_config.landingzone_key][each.value.private_dns_zone.key].id,
    each.value.private_dns_zone.id,
  null)
  managed_identities  = local.combined_objects_managed_identities
  application_gateway = try(each.value.addon_profile.ingress_application_gateway, null) != null ? try(each.value.addon_profile.ingress_application_gateway.lz_key, null) == null ? local.combined_objects_application_gateways[local.client_config.landingzone_key][each.value.addon_profile.ingress_application_gateway.key] : local.combined_objects_application_gateways[each.value.lz_key][each.value.addon_profile.ingress_application_gateway.key] : null

  admin_group_object_ids = try(each.value.admin_groups.azuread_group_keys, null) == null ? null : try(each.value.admin_groups.ids, [
    for group_key in try(each.value.admin_groups.azuread_groups.keys, {}) : local.combined_objects_azuread_groups[local.client_config.landingzone_key][group_key].id
  ])
}
