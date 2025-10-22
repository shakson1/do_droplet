################################################################################
# Local Values
################################################################################

locals {
  common_tags = concat(var.tags, [
    "managed-by:terraform",
    "module:digitalocean-droplet"
  ])

  # Computed VPC ID
  vpc_id = var.vpc_id != null ? var.vpc_id : digitalocean_vpc.this[0].id

  # Computed SSH keys
  ssh_keys = var.create_ssh_key ? [digitalocean_ssh_key.this[0].fingerprint] : var.ssh_key_fingerprints

  # Resource naming with environment prefix
  name_prefix = var.environment != null ? "${var.environment}-" : ""

  # Enhanced droplet configuration with defaults
  droplets_with_defaults = {
    for k, v in var.droplets : k => merge({
      region     = var.region
      monitoring = var.default_monitoring
      backups    = var.default_backups
      tags       = []
    }, v)
  }

  # Enhanced volume configuration with defaults
  volumes_with_defaults = {
    for k, v in var.volumes : k => merge({
      region          = var.region
      description     = "Managed by Terraform"
      filesystem_type = "ext4"
      tags            = []
    }, v)
  }
} 