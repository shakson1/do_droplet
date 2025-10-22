################################################################################
# Data Sources
################################################################################

# Data source for existing VPC (if provided)
# Used for validation and reference purposes
data "digitalocean_vpc" "existing" {
  count = var.vpc_id != null ? 1 : 0
  id    = var.vpc_id
}

# Data source for existing firewall (if provided)
# Used when attaching droplets to an existing firewall
data "digitalocean_firewall" "existing" {
  count       = var.existing_firewall_id != null ? 1 : 0
  firewall_id = var.existing_firewall_id
} 