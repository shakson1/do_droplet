variable "do_token" {
  description = "DigitalOcean API token."
  type        = string
  sensitive   = true
}

# Example: Use an existing VPC (uncomment and set your VPC ID)
# variable "vpc_id" {
#   description = "Existing VPC ID."
#   type        = string
#   default     = null
# }

module "doks_droplets" {
  source     = "../../"
  do_token   = var.do_token
  region     = "nyc1"

  # Use an existing SSH key (set create_ssh_key to false and provide fingerprints)
  create_ssh_key = false
  ssh_key_fingerprints = ["your:ssh:key:fingerprint:here"]

  # Uncomment to create a new SSH key instead
  # create_ssh_key = true
  # ssh_key_name   = "my-key"
  # ssh_public_key = file("~/.ssh/id_rsa.pub")

  # Uncomment to use a custom VPC
  # vpc_id = var.vpc_id

  tags = ["env:prod", "team:devops"]

  droplets = [
    {
      name  = "web-1"
      size  = "s-2vcpu-4gb"
      image = "ubuntu-22-04-x64"
      region = "nyc1"
      tags  = ["web", "frontend"]
      user_data_template = "${path.module}/cloud-init-web1.tpl"
      monitoring = true
      backups    = true
    },
    {
      name  = "web-2"
      size  = "s-2vcpu-4gb"
      image = "ubuntu-22-04-x64"
      region = "nyc3"
      tags  = ["web", "frontend"]
      user_data_file = "${path.module}/cloud-init-web2.yaml"
      monitoring = true
      backups    = false
    },
    {
      name  = "db-1"
      size  = "s-4vcpu-8gb"
      image = "ubuntu-22-04-x64"
      region = "sfo3"
      tags  = ["db", "backend"]
      user_data = "#!/bin/bash\necho 'Hello from db-1' > /root/hello.txt"
      monitoring = false
      backups    = true
    }
  ]

  volumes = [
    {
      name = "data-vol"
      size = 100
      region = "nyc1"
      description = "Shared data volume"
    },
    {
      name = "db-vol"
      size = 200
      region = "sfo3"
      description = "Database volume"
    }
  ]

  volume_attachments = [
    { droplet_name = "web-1", volume_name = "data-vol" },
    { droplet_name = "web-2", volume_name = "data-vol" },
    { droplet_name = "db-1",  volume_name = "db-vol" }
  ]

  floating_ips = [
    { droplet_name = "web-1" },
    { droplet_name = "db-1" }
  ]

  enable_firewall = true
  firewall_name   = "prod-firewall"
  firewall_inbound_rules = [
    {
      protocol = "tcp"
      port_range = "22"
      source_addresses = ["203.0.113.10/32", "::1/128"]
    },
    {
      protocol = "tcp"
      port_range = "80"
      source_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol = "tcp"
      port_range = "443"
      source_addresses = ["0.0.0.0/0", "::/0"]
    }
  ]
  firewall_outbound_rules = [
    {
      protocol = "icmp"
      destination_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol = "tcp"
      port_range = "all"
      destination_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol = "udp"
      port_range = "all"
      destination_addresses = ["0.0.0.0/0", "::/0"]
    }
  ]

  default_user_data_template = "${path.module}/cloud-init-default.tpl"
  default_monitoring = true
  default_backups    = false
}

output "droplet_public_ips" {
  value = module.doks_droplets.droplet_public_ips
}
output "floating_ip_addresses" {
  value = module.doks_droplets.floating_ip_addresses
}
output "ssh_key_fingerprint" {
  value = module.doks_droplets.ssh_key_fingerprint
}
output "droplet_hostnames" {
  value = module.doks_droplets.droplet_hostnames
}
output "volume_attachments" {
  value = module.doks_droplets.volume_attachments
}
output "ssh_connection_strings" {
  value = module.doks_droplets.ssh_connection_strings
  sensitive = true
}
output "firewall_id" {
  value = module.doks_droplets.firewall_id
}
output "vpc_id" {
  value = module.doks_droplets.vpc_id
} 