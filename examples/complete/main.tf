terraform {
  required_version = ">= 1.5.0"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.34.1"
    }
  }
}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.do_token
}

variable "do_token" {
  description = "DigitalOcean API token."
  type        = string
  sensitive   = true
}

module "doks_droplets" {
  source = "../../"

  region = "nyc1"
  environment = "prod"

  # Security: Prevent accidental destruction in production
  prevent_destroy = true

  # Use an existing SSH key (set create_ssh_key to false and provide fingerprints)
  create_ssh_key       = false
  ssh_key_fingerprints = ["your:ssh:key:fingerprint:here"]

  # Uncomment to create a new SSH key instead
  # create_ssh_key = true
  # ssh_key_name   = "my-key"
  # ssh_public_key = file("~/.ssh/id_rsa.pub")

  # Uncomment to use a custom VPC
  # vpc_id = var.vpc_id

  tags = ["env:prod", "team:devops", "project:webapp"]

  # User data variables for templates
  user_data_vars = {
    domain_name = "example.com"
    app_version = "v1.0.0"
    db_host     = "db.internal"
  }

  droplets = [
    {
      name               = "web-1"
      size               = "s-2vcpu-4gb"
      image              = "ubuntu-22-04-x64"
      region             = "nyc1"
      tags               = ["web", "frontend", "load-balancer"]
      user_data_template = "${path.module}/cloud-init-web1.tpl"
      monitoring         = true
      backups            = true
    },
    {
      name           = "web-2"
      size           = "s-2vcpu-4gb"
      image          = "ubuntu-22-04-x64"
      region         = "nyc3"
      tags           = ["web", "frontend", "load-balancer"]
      user_data_file = "${path.module}/cloud-init-web2.yaml"
      monitoring     = true
      backups        = false
    },
    {
      name       = "db-1"
      size       = "s-4vcpu-8gb"
      image      = "ubuntu-22-04-x64"
      region     = "sfo3"
      tags       = ["db", "backend"]
      user_data  = "#!/bin/bash\necho 'Hello from db-1' > /root/hello.txt"
      monitoring = false
      backups    = true
    }
  ]

  volumes = [
    {
      name        = "data-vol"
      size        = 100
      region      = "nyc1"
      description = "Shared data volume"
      tags        = ["data", "shared"]
    },
    {
      name        = "db-vol"
      size        = 200
      region      = "sfo3"
      description = "Database volume"
      tags        = ["data", "database"]
    }
  ]

  volume_attachments = [
    { droplet_name = "web-1", volume_name = "data-vol" },
    { droplet_name = "web-2", volume_name = "data-vol" },
    { droplet_name = "db-1", volume_name = "db-vol" }
  ]

  floating_ips = [
    { droplet_name = "web-1" },
    { droplet_name = "db-1" }
  ]

  # Enhanced firewall with better security
  enable_firewall = true
  firewall_name   = "prod-firewall"
  firewall_inbound_rules = [
    {
      protocol         = "tcp"
      port_range       = "22"
      source_addresses = ["203.0.113.10/32", "::1/128"] # Restrict SSH access
    },
    {
      protocol         = "tcp"
      port_range       = "80"
      source_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol         = "tcp"
      port_range       = "443"
      source_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol         = "tcp"
      port_range       = "3306"
      source_addresses = ["10.0.0.0/8"] # Internal DB access only
    }
  ]
  firewall_outbound_rules = [
    {
      protocol              = "icmp"
      destination_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol              = "tcp"
      port_range            = "all"
      destination_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol              = "udp"
      port_range            = "all"
      destination_addresses = ["0.0.0.0/0", "::/0"]
    }
  ]

  # Load Balancer configuration
  enable_load_balancer = true
  load_balancer_name   = "web-lb"
  load_balancer_forwarding_rules = [
    {
      entry_port      = 80
      entry_protocol  = "http"
      target_port     = 80
      target_protocol = "http"
    },
    {
      entry_port      = 443
      entry_protocol  = "https"
      target_port     = 443
      target_protocol = "https"
      # certificate_id = "your-cert-id" # Uncomment if using SSL
    }
  ]
  load_balancer_healthcheck = {
    protocol                 = "http"
    port                     = 80
    path                     = "/health"
    check_interval_seconds   = 10
    response_timeout_seconds = 5
    healthy_threshold        = 3
    unhealthy_threshold      = 5
  }
  load_balancer_droplet_tag = "load-balancer"

  default_user_data_template = "${path.module}/cloud-init-default.tpl"
  default_monitoring         = true
  default_backups            = false
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
  value     = module.doks_droplets.ssh_connection_strings
  sensitive = true
}
output "firewall_id" {
  value = module.doks_droplets.firewall_id
}
output "vpc_id" {
  value = module.doks_droplets.vpc_id
}
output "load_balancer_ip" {
  value = module.doks_droplets.load_balancer_ip
}
output "summary" {
  value = module.doks_droplets.summary
} 