# Data source for SSH keys (if using existing keys)
data "digitalocean_ssh_keys" "existing" {
  count = var.create_ssh_key ? 0 : 1
  dynamic "filter" {
    for_each = length(var.ssh_key_fingerprints) > 0 ? [1] : []
    content {
      key    = "fingerprint"
      values = var.ssh_key_fingerprints
    }
  }
}

# Data source for available images
data "digitalocean_images" "available" {
  filter {
    key    = "distribution"
    values = ["Ubuntu", "CentOS", "Debian", "Fedora"]
  }
  filter {
    key    = "type"
    values = ["distribution"]
  }
  filter {
    key    = "status"
    values = ["available"]
  }
}

# Data source for available sizes
data "digitalocean_sizes" "available" {
  filter {
    key    = "regions"
    values = [var.region]
  }
  filter {
    key    = "available"
    values = [true]
  }
}

# Data source for existing VPC (if provided)
data "digitalocean_vpc" "existing" {
  count = var.vpc_id != null ? 1 : 0
  id    = var.vpc_id
}

# Data source for existing firewall (if provided)
data "digitalocean_firewall" "existing" {
  count       = var.existing_firewall_id != null ? 1 : 0
  firewall_id = var.existing_firewall_id
} 