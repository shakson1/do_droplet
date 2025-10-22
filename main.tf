################################################################################
# VPC
################################################################################

# Create a new VPC if one is not provided
# This enables private networking between droplets
resource "digitalocean_vpc" "this" {
  count  = var.vpc_id == null ? 1 : 0
  name   = "${local.name_prefix}${var.vpc_name}"
  region = var.region

  lifecycle {
    prevent_destroy = false
  }
}

################################################################################
# SSH Key
################################################################################

# Create a new SSH key in DigitalOcean if requested
# Otherwise, use existing SSH keys via fingerprints
resource "digitalocean_ssh_key" "this" {
  count      = var.create_ssh_key ? 1 : 0
  name       = "${local.name_prefix}${var.ssh_key_name}"
  public_key = var.ssh_public_key

  lifecycle {
    prevent_destroy = false
  }
}

################################################################################
# Droplets
################################################################################

# Create multiple droplets based on the droplets variable
# Supports per-droplet configuration including size, image, region, and user data
resource "digitalocean_droplet" "this" {
  for_each = { for d in var.droplets : d.name => d }

  name     = "${local.name_prefix}${each.value.name}"
  region   = each.value.region != null ? each.value.region : var.region
  size     = each.value.size
  image    = each.value.image
  tags     = concat(each.value.tags != null ? each.value.tags : [], local.common_tags)
  vpc_uuid = local.vpc_id
  ssh_keys = local.ssh_keys

  # User data with fallback hierarchy:
  # 1. Per-droplet template file
  # 2. Per-droplet static file
  # 3. Per-droplet inline data
  # 4. Module-level default template
  # 5. Module-level default file
  user_data = try(
    can(each.value.user_data_template) && each.value.user_data_template != null ? templatefile(each.value.user_data_template, merge(var.user_data_vars, { droplet_name = each.value.name })) :
    can(each.value.user_data_file) && each.value.user_data_file != null ? file(each.value.user_data_file) :
    can(each.value.user_data) && each.value.user_data != null ? each.value.user_data :
    var.default_user_data_template != null ? templatefile(var.default_user_data_template, merge(var.user_data_vars, { droplet_name = each.value.name })) :
    var.default_user_data_file != null ? file(var.default_user_data_file) :
    null,
    null
  )

  # Monitoring and backups with per-droplet override capability
  monitoring = can(each.value.monitoring) && each.value.monitoring != null ? each.value.monitoring : var.default_monitoring
  backups    = can(each.value.backups) && each.value.backups != null ? each.value.backups : var.default_backups

  lifecycle {
    prevent_destroy = false
    ignore_changes  = [image] # Prevent recreation on image updates
  }
}

################################################################################
# Block Storage Volumes
################################################################################

# Create block storage volumes for persistent data
# Volumes can be attached to droplets in the same region
resource "digitalocean_volume" "this" {
  for_each = { for v in var.volumes : v.name => v }

  region          = each.value.region != null ? each.value.region : var.region
  name            = "${local.name_prefix}${each.value.name}"
  size            = each.value.size
  description     = each.value.description
  filesystem_type = each.value.filesystem_type
  snapshot_id     = each.value.snapshot_id
  tags            = concat(each.value.tags != null ? each.value.tags : [], local.common_tags)

  lifecycle {
    prevent_destroy = false
  }
}

# Attach volumes to droplets
# Each volume can only be attached to one droplet at a time
resource "digitalocean_volume_attachment" "this" {
  for_each = { for va in var.volume_attachments : "${va.droplet_name}-${va.volume_name}" => va }

  droplet_id = digitalocean_droplet.this[each.value.droplet_name].id
  volume_id  = digitalocean_volume.this[each.value.volume_name].id

  lifecycle {
    prevent_destroy = false
  }
}

################################################################################
# Floating IPs
################################################################################

# Create and assign floating IPs to droplets
# Floating IPs provide static public IP addresses
# that can be reassigned between droplets for high availability
resource "digitalocean_floating_ip" "this" {
  for_each = { for f in var.floating_ips : f.droplet_name => f }

  region     = digitalocean_droplet.this[each.value.droplet_name].region
  droplet_id = digitalocean_droplet.this[each.value.droplet_name].id

  lifecycle {
    prevent_destroy = false
  }
}

################################################################################
# Firewall
################################################################################

# Create a cloud firewall to control traffic to droplets
# Supports both inbound and outbound rules
# Can filter by IP addresses, tags, or other resources
resource "digitalocean_firewall" "this" {
  count = var.enable_firewall && var.existing_firewall_id == null ? 1 : 0

  name        = "${local.name_prefix}${var.firewall_name}"
  droplet_ids = [for d in digitalocean_droplet.this : d.id]
  tags        = local.common_tags

  # Inbound rules define what traffic can reach the droplets
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

  # Outbound rules define what traffic can leave the droplets
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

  lifecycle {
    prevent_destroy = false
  }
}

################################################################################
# Load Balancer
################################################################################

# Create a load balancer to distribute traffic across multiple droplets
# Includes health checks to automatically remove unhealthy droplets
# Droplets are selected by tag for automatic scaling
resource "digitalocean_loadbalancer" "this" {
  count = var.enable_load_balancer ? 1 : 0

  name     = "${local.name_prefix}${var.load_balancer_name}"
  region   = var.region
  vpc_uuid = local.vpc_id

  # Forwarding rules define how traffic is routed
  # Supports HTTP, HTTPS, TCP, and UDP protocols
  dynamic "forwarding_rule" {
    for_each = var.load_balancer_forwarding_rules
    content {
      entry_port      = forwarding_rule.value.entry_port
      entry_protocol  = forwarding_rule.value.entry_protocol
      target_port     = forwarding_rule.value.target_port
      target_protocol = forwarding_rule.value.target_protocol
      certificate_id  = try(forwarding_rule.value.certificate_id, null)
      tls_passthrough = try(forwarding_rule.value.tls_passthrough, null)
    }
  }

  # Health check configuration
  # Unhealthy droplets are automatically removed from the pool
  healthcheck {
    protocol                 = var.load_balancer_healthcheck.protocol
    port                     = var.load_balancer_healthcheck.port
    path                     = try(var.load_balancer_healthcheck.path, null)
    check_interval_seconds   = try(var.load_balancer_healthcheck.check_interval_seconds, 10)
    response_timeout_seconds = try(var.load_balancer_healthcheck.response_timeout_seconds, 5)
    healthy_threshold        = try(var.load_balancer_healthcheck.healthy_threshold, 3)
    unhealthy_threshold      = try(var.load_balancer_healthcheck.unhealthy_threshold, 5)
  }

  # Use tags to automatically include droplets in the load balancer
  droplet_tag = var.load_balancer_droplet_tag

  lifecycle {
    prevent_destroy = false
  }
} 