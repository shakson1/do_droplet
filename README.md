# DigitalOcean Droplet Terraform Module

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.5.0-623CE4.svg)](https://www.terraform.io/)
[![DigitalOcean](https://img.shields.io/badge/DigitalOcean-Provider-0080FF.svg)](https://registry.terraform.io/providers/digitalocean/digitalocean/latest)

A production-ready Terraform module for deploying and managing DigitalOcean Droplets with advanced features including load balancing, firewalls, block storage, and automated backups.

## 🌟 Features

- **Multiple Droplets**: Deploy single or multiple droplets with flexible configuration
- **VPC Networking**: Automatic VPC creation or use existing VPCs for private networking
- **Load Balancing**: Built-in load balancer support with health checks and SSL
- **Block Storage**: Attach persistent block storage volumes to droplets
- **Floating IPs**: Static IP addresses that can be reassigned for high availability
- **Cloud Firewall**: Comprehensive firewall rules with source/destination filtering
- **SSH Key Management**: Create new keys or use existing SSH keys
- **User Data**: Support for cloud-init with templates, files, or inline configuration
- **Monitoring & Backups**: Optional DigitalOcean monitoring and automated backups
- **Auto-Tagging**: Automatic resource tagging for organization and cost tracking
- **Multi-Region**: Deploy droplets across different DigitalOcean regions
- **Production Ready**: Includes lifecycle policies, validation, and best practices

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Usage Examples](#usage-examples)
- [Module Configuration](#module-configuration)
- [Advanced Features](#advanced-features)
- [Best Practices](#best-practices)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.5.0
- [DigitalOcean Account](https://cloud.digitalocean.com/registrations/new)
- [DigitalOcean API Token](https://cloud.digitalocean.com/account/api/tokens) with write permissions
- (Optional) Existing SSH key added to DigitalOcean account

## 🚀 Quick Start

### Minimal Example

Deploy a single droplet with minimal configuration:

```hcl
terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.34.1"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

module "droplet" {
  source = "github.com/yourusername/digitalocean-droplet"

  region      = "nyc1"
  environment = "dev"

  ssh_key_fingerprints = ["your:ssh:key:fingerprint:here"]

  droplets = [
    {
      name  = "web-server"
      size  = "s-1vcpu-1gb"
      image = "ubuntu-22-04-x64"
    }
  ]
}

output "droplet_ip" {
  value = module.droplet.droplet_public_ips["web-server"]
}
```

### Apply the Configuration

```bash
terraform init
terraform plan
terraform apply
```

## 📚 Usage Examples

### Basic Web Server

```hcl
module "web_server" {
  source = "github.com/yourusername/digitalocean-droplet"

  region      = "nyc1"
  environment = "production"

  ssh_key_fingerprints = ["aa:bb:cc:dd:ee:ff:00:11:22:33:44:55:66:77:88:99"]

  droplets = [
    {
      name       = "web-1"
      size       = "s-2vcpu-4gb"
      image      = "ubuntu-22-04-x64"
      monitoring = true
      backups    = true
      tags       = ["web", "production"]
    }
  ]

  # Firewall configuration
  enable_firewall = true
  firewall_inbound_rules = [
    {
      protocol         = "tcp"
      port_range       = "22"
      source_addresses = ["your.ip.address/32"]
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

  tags = ["project:webapp", "team:devops"]
}
```

### High Availability Setup with Load Balancer

```hcl
module "ha_web_cluster" {
  source = "github.com/yourusername/digitalocean-droplet"

  region      = "nyc1"
  environment = "production"

  ssh_key_fingerprints = var.ssh_key_fingerprints

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

  # Load Balancer
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

  load_balancer_droplet_tag = "load-balanced"

  # Firewall
  enable_firewall = true
  firewall_inbound_rules = [
    {
      protocol         = "tcp"
      port_range       = "22"
      source_addresses = ["your.office.ip/32"]
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

  default_monitoring = true
}
```

### With Block Storage Volumes

```hcl
module "app_with_storage" {
  source = "github.com/yourusername/digitalocean-droplet"

  region      = "nyc1"
  environment = "production"

  ssh_key_fingerprints = var.ssh_key_fingerprints

  droplets = [
    {
      name  = "app-server"
      size  = "s-2vcpu-4gb"
      image = "ubuntu-22-04-x64"
    }
  ]

  volumes = [
    {
      name        = "app-data"
      size        = 100
      description = "Application data volume"
      tags        = ["data", "production"]
    }
  ]

  volume_attachments = [
    {
      droplet_name = "app-server"
      volume_name  = "app-data"
    }
  ]
}
```

### With User Data Templates

```hcl
module "web_with_userdata" {
  source = "github.com/yourusername/digitalocean-droplet"

  region      = "nyc1"
  environment = "production"

  ssh_key_fingerprints = var.ssh_key_fingerprints

  # Variables passed to user data templates
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
      user_data_template = "./cloud-init-web.tpl"
    }
  ]

  default_user_data_template = "./cloud-init-default.tpl"
}
```

## 🔧 Module Configuration

### Core Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| region | Default region for resources | `string` | `"nyc1"` | no |
| environment | Environment name (e.g., prod, dev, staging) | `string` | `null` | no |
| prevent_destroy | Prevent accidental resource destruction | `bool` | `false` | no |
| vpc_id | Existing VPC ID to use | `string` | `null` | no |
| vpc_name | Name for new VPC if created | `string` | `"droplet-vpc"` | no |

### SSH Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| create_ssh_key | Create a new SSH key in DigitalOcean | `bool` | `false` | no |
| ssh_key_name | Name for the SSH key if created | `string` | `"droplet-key"` | no |
| ssh_public_key | Public key content if creating new key | `string` | `""` | no |
| ssh_key_fingerprints | List of existing SSH key fingerprints | `list(string)` | `[]` | no |

### Droplet Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| droplets | List of droplet configurations | `list(object)` | n/a | yes |
| default_monitoring | Enable monitoring by default | `bool` | `false` | no |
| default_backups | Enable backups by default | `bool` | `false` | no |
| default_user_data_template | Default user data template | `string` | `null` | no |
| default_user_data_file | Default user data file | `string` | `null` | no |
| user_data_vars | Variables for user data templates | `map(any)` | `{}` | no |

### Droplet Object Structure

```hcl
droplets = [
  {
    name               = string       # Required: Droplet name
    size               = string       # Required: Size slug (e.g., "s-1vcpu-1gb")
    image              = string       # Required: Image slug (e.g., "ubuntu-22-04-x64")
    region             = string       # Optional: Override default region
    tags               = list(string) # Optional: Additional tags
    monitoring         = bool         # Optional: Enable monitoring
    backups            = bool         # Optional: Enable backups
    user_data          = string       # Optional: Inline user data
    user_data_file     = string       # Optional: Path to user data file
    user_data_template = string       # Optional: Path to template file
  }
]
```

### Firewall Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| enable_firewall | Create and configure firewall | `bool` | `false` | no |
| firewall_name | Name for the firewall | `string` | `"droplet-firewall"` | no |
| firewall_inbound_rules | List of inbound rules | `list(object)` | SSH only | no |
| firewall_outbound_rules | List of outbound rules | `list(object)` | All traffic | no |
| existing_firewall_id | Use existing firewall ID | `string` | `null` | no |

### Load Balancer Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| enable_load_balancer | Create a load balancer | `bool` | `false` | no |
| load_balancer_name | Name for the load balancer | `string` | `"droplet-lb"` | no |
| load_balancer_forwarding_rules | Forwarding rules | `list(object)` | HTTP:80 | no |
| load_balancer_healthcheck | Health check config | `object` | TCP:80 | no |
| load_balancer_droplet_tag | Tag to identify droplets | `string` | `"web"` | no |

### Volume Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| volumes | List of volume configurations | `list(object)` | `[]` | no |
| volume_attachments | List of volume attachments | `list(object)` | `[]` | no |

### Floating IP Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| floating_ips | List of floating IP assignments | `list(object)` | `[]` | no |

## 📤 Outputs

| Name | Description |
|------|-------------|
| droplet_ids | Map of droplet names to IDs |
| droplet_public_ips | Map of droplet names to public IPs |
| droplet_private_ips | Map of droplet names to private IPs |
| droplet_status | Map of droplet names to status |
| droplet_hostnames | Map of droplet names to hostnames |
| droplet_tags | Map of droplet names to tags |
| volume_ids | Map of volume names to IDs |
| volume_names | Map of volume names to full names |
| volume_attachments | Map of droplets to attached volumes |
| floating_ip_addresses | Map of droplet names to floating IPs |
| ssh_key_fingerprint | SSH key fingerprint if created |
| ssh_connection_strings | SSH connection strings (sensitive) |
| firewall_id | Firewall ID if created |
| vpc_id | VPC ID used |
| load_balancer_id | Load balancer ID if created |
| load_balancer_ip | Load balancer IP address if created |
| load_balancer_urn | Load balancer URN if created |
| summary | Summary of created resources |

## 🎯 Advanced Features

### Custom VPC Configuration

```hcl
module "droplet" {
  source = "github.com/yourusername/digitalocean-droplet"

  # Use existing VPC
  vpc_id = "vpc-12345678-1234-1234-1234-123456789012"

  # Or create new VPC with custom name
  # vpc_id = null
  # vpc_name = "production-vpc"

  droplets = [...]
}
```

### Multi-Region Deployment

```hcl
module "droplet" {
  source = "github.com/yourusername/digitalocean-droplet"

  region = "nyc1" # Default region

  droplets = [
    {
      name   = "web-nyc"
      region = "nyc1"  # Use default
      size   = "s-1vcpu-1gb"
      image  = "ubuntu-22-04-x64"
    },
    {
      name   = "web-sfo"
      region = "sfo3"  # Override region
      size   = "s-1vcpu-1gb"
      image  = "ubuntu-22-04-x64"
    },
    {
      name   = "web-ams"
      region = "ams3"  # Override region
      size   = "s-1vcpu-1gb"
      image  = "ubuntu-22-04-x64"
    }
  ]
}
```

### Dynamic Firewall Rules

```hcl
locals {
  office_ips = ["203.0.113.10/32", "198.51.100.20/32"]
  
  ssh_rules = [
    for ip in local.office_ips : {
      protocol         = "tcp"
      port_range       = "22"
      source_addresses = [ip]
    }
  ]
}

module "droplet" {
  source = "github.com/yourusername/digitalocean-droplet"

  enable_firewall        = true
  firewall_inbound_rules = concat(local.ssh_rules, [
    {
      protocol         = "tcp"
      port_range       = "80"
      source_addresses = ["0.0.0.0/0", "::/0"]
    }
  ])

  droplets = [...]
}
```

## 🔒 Best Practices

### Security

1. **Restrict SSH Access**: Limit SSH to known IP addresses
   ```hcl
   firewall_inbound_rules = [
     {
       protocol         = "tcp"
       port_range       = "22"
       source_addresses = ["your.office.ip/32"]
     }
   ]
   ```

2. **Enable Monitoring**: Track droplet performance
   ```hcl
   default_monitoring = true
   ```

3. **Use VPC**: Enable private networking
   ```hcl
   # VPC is created automatically or use existing
   vpc_id = var.vpc_id
   ```

4. **Enable Backups**: For production workloads
   ```hcl
   default_backups = true
   ```

### High Availability

1. **Use Load Balancers**: Distribute traffic across multiple droplets
2. **Deploy Across Regions**: For geographic redundancy
3. **Use Floating IPs**: For quick failover
4. **Enable Health Checks**: Automatic removal of unhealthy droplets

### Cost Optimization

1. **Right-Size Droplets**: Start small and scale up
2. **Use Snapshots**: For development environments
3. **Cleanup Unused Resources**: Remove unattached volumes and IPs
4. **Monitor Bandwidth**: Track transfer costs

### Infrastructure as Code

1. **Version Control**: Store configurations in Git
2. **Use Modules**: Reuse configurations across projects
3. **Tag Resources**: For cost tracking and organization
4. **Document Changes**: Keep CHANGELOG.md updated

## 🛠️ Development

### Prerequisites

```bash
# Install development tools
brew install terraform terraform-docs tflint pre-commit

# Or using pip for checkov
pip install checkov
```

### Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/digitalocean-droplet.git
cd digitalocean-droplet

# Install pre-commit hooks
pre-commit install

# Initialize Terraform
make init

# Validate configuration
make validate
```

### Testing

```bash
# Run unit tests
cd test
go test -v ./...

# Run integration tests (requires DigitalOcean token)
export DO_TOKEN=your_token_here
go test -v -timeout 30m

# Test examples
make test-examples
```

### Code Quality

```bash
# Format code
make format

# Run linter
make lint

# Generate documentation
make docs

# Run security checks
make security

# Run all checks
make pre-commit
```

## 📁 Project Structure

```
.
├── .editorconfig              # Editor configuration
├── .gitignore                 # Git ignore rules
├── .pre-commit-config.yaml    # Pre-commit hooks
├── .terraform-docs.yml        # Documentation config
├── .tflint.hcl               # Linter configuration
├── CHANGELOG.md              # Version history
├── CONTRIBUTING.md           # Contribution guidelines
├── LICENSE                   # MIT License
├── Makefile                  # Development commands
├── README.md                 # This file
├── data.tf                   # Data sources
├── locals.tf                 # Local values
├── main.tf                   # Main resources
├── outputs.tf                # Output values
├── variables.tf              # Input variables
├── versions.tf               # Provider versions
├── examples/                 # Usage examples
│   ├── minimal/              # Minimal example
│   ├── complete/             # Complete example
│   └── with-load-balancer/   # Load balancer example
└── test/                     # Automated tests
    ├── integration_test.go   # Integration tests
    └── unit_test.go          # Unit tests
```

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

### Quick Contribution Guide

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests and quality checks (`make pre-commit`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Terraform](https://www.terraform.io/) by HashiCorp
- [DigitalOcean](https://www.digitalocean.com/) for their excellent cloud platform
- All [contributors](https://github.com/yourusername/digitalocean-droplet/graphs/contributors) to this project

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/digitalocean-droplet/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/digitalocean-droplet/discussions)
- **Email**: your-email@example.com

## 🗺️ Roadmap

- [ ] Support for DigitalOcean Kubernetes (DOKS)
- [ ] Database cluster integration
- [ ] Spaces (S3-compatible storage) support
- [ ] CDN integration
- [ ] Monitoring alerts configuration
- [ ] Auto-scaling groups
- [ ] Terraform Cloud/Enterprise support

---

**Made with ❤️ by the community**
