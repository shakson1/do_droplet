output "droplet_ids" {
  description = "IDs of all created droplets."
  value       = { for k, d in digitalocean_droplet.this : k => d.id }
}

output "droplet_public_ips" {
  description = "Public IPv4 addresses of all droplets."
  value       = { for k, d in digitalocean_droplet.this : k => d.ipv4_address }
}

output "droplet_private_ips" {
  description = "Private IPv4 addresses of all droplets."
  value       = { for k, d in digitalocean_droplet.this : k => d.ipv4_address_private }
}

output "droplet_status" {
  description = "Status of all droplets."
  value       = { for k, d in digitalocean_droplet.this : k => d.status }
}

output "volume_ids" {
  description = "IDs of all created volumes."
  value       = { for k, v in digitalocean_volume.this : k => v.id }
}

output "floating_ip_addresses" {
  description = "Floating IP addresses assigned to droplets."
  value       = { for k, f in digitalocean_floating_ip.this : k => f.ip_address }
}

output "ssh_key_fingerprint" {
  description = "Fingerprint of the created SSH key (if any)."
  value       = try(digitalocean_ssh_key.this[0].fingerprint, null)
}

output "droplet_hostnames" {
  description = "Hostnames of all created droplets."
  value       = { for k, d in digitalocean_droplet.this : k => d.name }
}

output "volume_names" {
  description = "Names of all created volumes."
  value       = { for k, v in digitalocean_volume.this : k => v.name }
}

output "volume_attachments" {
  description = "Map of droplet names to the list of attached volume names."
  value = {
    for d_name, d in digitalocean_droplet.this :
    d_name => compact([
      for va_key, va in digitalocean_volume_attachment.this :
      va.droplet_id == d.id ? digitalocean_volume.this[va.volume_id].name : null
    ])
  }
}

output "ssh_connection_strings" {
  description = "SSH connection strings for each droplet (e.g., 'ssh root@<public_ip>')."
  value       = { for k, d in digitalocean_droplet.this : k => "ssh root@${d.ipv4_address}" }
  sensitive   = true
}

output "firewall_id" {
  description = "ID of the created firewall (if any)."
  value       = try(digitalocean_firewall.this[0].id, null)
}

output "vpc_id" {
  description = "ID of the VPC used by the droplets."
  value       = var.vpc_id != null ? var.vpc_id : digitalocean_vpc.this[0].id
}

output "droplet_tags" {
  description = "Tags applied to each droplet."
  value       = { for k, d in digitalocean_droplet.this : k => d.tags }
}

# Load Balancer Outputs
output "load_balancer_id" {
  description = "ID of the created load balancer (if any)."
  value       = try(digitalocean_loadbalancer.this[0].id, null)
}

output "load_balancer_ip" {
  description = "IP address of the load balancer (if any)."
  value       = try(digitalocean_loadbalancer.this[0].ip, null)
}

output "load_balancer_urn" {
  description = "URN of the load balancer (if any)."
  value       = try(digitalocean_loadbalancer.this[0].urn, null)
}

# Summary Outputs
output "summary" {
  description = "Summary of all created resources."
  value = {
    droplets_count        = length(digitalocean_droplet.this)
    volumes_count         = length(digitalocean_volume.this)
    floating_ips_count    = length(digitalocean_floating_ip.this)
    firewall_created      = var.enable_firewall && var.existing_firewall_id == null
    load_balancer_created = var.enable_load_balancer
    vpc_created           = var.vpc_id == null
    ssh_key_created       = var.create_ssh_key
  }
} 