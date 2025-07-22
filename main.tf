// DigitalOcean provider
provider "digitalocean" {
  token = var.do_token
}

// Optionally create a VPC if vpc_id is not provided
resource "digitalocean_vpc" "this" {
  count  = var.vpc_id == null ? 1 : 0
  name   = var.vpc_name
  region = var.region
}

// SSH key (optional creation)
resource "digitalocean_ssh_key" "this" {
  count      = var.create_ssh_key ? 1 : 0
  name       = var.ssh_key_name
  public_key = var.ssh_public_key
}

// Droplets (multiple)
resource "digitalocean_droplet" "this" {
  for_each = { for d in var.droplets : d.name => d }
  name     = each.value.name
  region   = each.value.region != null ? each.value.region : var.region
  size     = each.value.size
  image    = each.value.image
  tags     = each.value.tags
  vpc_uuid = var.vpc_id != null ? var.vpc_id : digitalocean_vpc.this[0].id
  ssh_keys = var.create_ssh_key ? [digitalocean_ssh_key.this[0].fingerprint] : var.ssh_key_fingerprints
  user_data = (
    can(each.value.user_data_template) && each.value.user_data_template != null ? templatefile(each.value.user_data_template, {}) :
    can(each.value.user_data_file) && each.value.user_data_file != null ? file(each.value.user_data_file) :
    can(each.value.user_data) && each.value.user_data != null ? each.value.user_data :
    var.default_user_data_template != null ? templatefile(var.default_user_data_template, {}) :
    var.default_user_data_file != null ? file(var.default_user_data_file) :
    null
  )
  monitoring = can(each.value.monitoring) && each.value.monitoring != null ? each.value.monitoring : var.default_monitoring
  backups    = can(each.value.backups) && each.value.backups != null ? each.value.backups : var.default_backups
}

// Volumes (multiple, attached to droplets)
resource "digitalocean_volume" "this" {
  for_each        = { for v in var.volumes : v.name => v }
  region          = each.value.region != null ? each.value.region : var.region
  name            = each.value.name
  size            = each.value.size
  description     = each.value.description
  filesystem_type = each.value.filesystem_type
  snapshot_id     = each.value.snapshot_id
  tags            = var.tags
}

resource "digitalocean_volume_attachment" "this" {
  for_each   = { for va in var.volume_attachments : "${va.droplet_name}-${va.volume_name}" => va }
  droplet_id = digitalocean_droplet.this[each.value.droplet_name].id
  volume_id  = digitalocean_volume.this[each.value.volume_name].id
}

// Floating IPs (optional, assign to droplets)
resource "digitalocean_floating_ip" "this" {
  for_each   = { for f in var.floating_ips : f.droplet_name => f }
  region     = digitalocean_droplet.this[each.value.droplet_name].region
  droplet_id = digitalocean_droplet.this[each.value.droplet_name].id
}

resource "digitalocean_firewall" "this" {
  count       = var.enable_firewall && var.existing_firewall_id == null ? 1 : 0
  name        = var.firewall_name
  droplet_ids = [for d in digitalocean_droplet.this : d.id]
  tags        = var.tags

  dynamic "inbound_rule" {
    for_each = var.firewall_inbound_rules
    content {
      protocol                  = inbound_rule.value.protocol
      port_range                = inbound_rule.value.port_range
      source_addresses          = try(inbound_rule.value.source_addresses, null)
      source_tags               = try(inbound_rule.value.source_tags, null)
      source_droplet_ids        = try(inbound_rule.value.source_droplet_ids, null)
      source_load_balancer_uids = try(inbound_rule.value.source_load_balancer_uids, null)
      source_kubernetes_ids     = try(inbound_rule.value.source_kubernetes_ids, null)
    }
  }

  dynamic "outbound_rule" {
    for_each = var.firewall_outbound_rules
    content {
      protocol                       = outbound_rule.value.protocol
      port_range                     = try(outbound_rule.value.port_range, null)
      destination_addresses          = try(outbound_rule.value.destination_addresses, null)
      destination_tags               = try(outbound_rule.value.destination_tags, null)
      destination_droplet_ids        = try(outbound_rule.value.destination_droplet_ids, null)
      destination_load_balancer_uids = try(outbound_rule.value.destination_load_balancer_uids, null)
      destination_kubernetes_ids     = try(outbound_rule.value.destination_kubernetes_ids, null)
    }
  }
} 