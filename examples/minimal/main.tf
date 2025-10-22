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

module "droplet" {
  source = "../../"

  region      = "nyc1"
  environment = "dev"

  # Use existing SSH key
  create_ssh_key       = false
  ssh_key_fingerprints = var.ssh_key_fingerprints

  # Minimal configuration - single droplet
  droplets = [
    {
      name  = "web-server"
      size  = "s-1vcpu-1gb"
      image = "ubuntu-22-04-x64"
    }
  ]

  tags = ["environment:dev", "managed-by:terraform"]
}

output "droplet_ip" {
  description = "Public IP of the droplet"
  value       = module.droplet.droplet_public_ips["web-server"]
}

output "ssh_command" {
  description = "SSH command to connect to the droplet"
  value       = module.droplet.ssh_connection_strings["web-server"]
  sensitive   = true
}

