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

module "web_cluster" {
  source = "../../"

  region      = "nyc1"
  environment = "production"

  # Prevent accidental destruction in production
  prevent_destroy = true

  # Use existing SSH key
  create_ssh_key       = false
  ssh_key_fingerprints = var.ssh_key_fingerprints

  # Multiple droplets for high availability
  droplets = [
    {
      name       = "web-1"
      size       = "s-2vcpu-4gb"
      image      = "ubuntu-22-04-x64"
      tags       = ["web", "load-balanced"]
      monitoring = true
      backups    = true
    },
    {
      name       = "web-2"
      size       = "s-2vcpu-4gb"
      image      = "ubuntu-22-04-x64"
      tags       = ["web", "load-balanced"]
      monitoring = true
      backups    = true
    },
    {
      name       = "web-3"
      size       = "s-2vcpu-4gb"
      image      = "ubuntu-22-04-x64"
      tags       = ["web", "load-balanced"]
      monitoring = true
      backups    = true
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
    }
  ]

  load_balancer_healthcheck = {
    protocol                 = "http"
    port                     = 80
    path                     = "/health"
    check_interval_seconds   = 10
    response_timeout_seconds = 5
    healthy_threshold        = 3
    unhealthy_threshold      = 3
  }

  # Tag to identify droplets for load balancer
  load_balancer_droplet_tag = "load-balanced"

  # Firewall configuration
  enable_firewall = true
  firewall_name   = "web-firewall"

  firewall_inbound_rules = [
    {
      protocol         = "tcp"
      port_range       = "22"
      source_addresses = var.allowed_ssh_ips
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
    }
  ]

  tags = ["environment:production", "project:webapp", "team:platform"]

  # Default monitoring for all droplets
  default_monitoring = true
}

# Output the load balancer IP
output "load_balancer_ip" {
  description = "IP address of the load balancer"
  value       = module.web_cluster.load_balancer_ip
}

output "droplet_ips" {
  description = "Private IPs of all web servers"
  value       = module.web_cluster.droplet_private_ips
}

output "summary" {
  description = "Deployment summary"
  value       = module.web_cluster.summary
}

