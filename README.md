# DigitalOcean Droplet Production Module

Deploy production-ready DigitalOcean Droplets with volume attachment, floating IPs, SSH configuration, firewalls, monitoring, backups, user data templating, load balancers, and more.

## 🚀 Features
- **Multiple droplets** (cluster or single) with environment-based naming
- **Volume creation and attachment** (multiple volumes per droplet)
- **Floating/static IPs** (DigitalOcean reserved IPs)
- **SSH key management** (create or use existing)
- **VPC support** (create or use existing)
- **Load balancer** with health checks and SSL support
- **All droplet options** (size, image, region, tags, user data, monitoring, backups, etc)
- **User data templating** (inline, file, or template per droplet or global)
- **Module-level and resource-level tags** with automatic tagging
- **Optional DigitalOcean firewall** (custom rules, auto-assignment)
- **Comprehensive outputs** (hostnames, IPs, SSH strings, volume info, firewall, VPC, load balancer, etc)
- **Robust input validation** and defaults
- **Lifecycle policies** to prevent accidental destruction
- **Environment-based resource naming** for better organization
- **Enhanced security practices** with restricted firewall rules

## 📋 Prerequisites
- DigitalOcean API token with write permissions
- Terraform >= 1.5.0
- (Optional) Existing SSH key fingerprints or public key for new key

## 🏗️ Usage

### Basic Example
```hcl
module "doks_droplets" {
  source     = "<YOUR_GITHUB_OR_REGISTRY_PATH>"
  do_token   = var.do_token
  region     = "nyc1"
  environment = "prod"

  # Security: Prevent accidental destruction in production
  prevent_destroy = true

  # Use an existing SSH key
  create_ssh_key = false
  ssh_key_fingerprints = ["your:ssh:key:fingerprint:here"]

  tags = ["env:prod", "team:devops", "project:webapp"]

  droplets = [
    {
      name  = "web-1"
      size  = "s-2vcpu-4gb"
      image = "ubuntu-22-04-x64"
      tags  = ["web", "frontend"]
      monitoring = true
      backups    = true
    }
  ]
}
```

### Advanced Example with Load Balancer
```hcl
module "doks_droplets" {
  source     = "<YOUR_GITHUB_OR_REGISTRY_PATH>"
  do_token   = var.do_token
  region     = "nyc1"
  environment = "prod"
  prevent_destroy = true

  # User data variables for templates
  user_data_vars = {
    domain_name = "example.com"
    app_version = "v1.0.0"
    db_host     = "db.internal"
  }

  droplets = [
    {
      name  = "web-1"
      size  = "s-2vcpu-4gb"
      image = "ubuntu-22-04-x64"
      tags  = ["web", "frontend", "load-balancer"]
      user_data_template = "${path.module}/cloud-init-web1.tpl"
      monitoring = true
      backups    = true
    },
    {
      name  = "web-2"
      size  = "s-2vcpu-4gb"
      image = "ubuntu-22-04-x64"
      tags  = ["web", "frontend", "load-balancer"]
      monitoring = true
      backups    = false
    }
  ]

  volumes = [
    {
      name = "data-vol"
      size = 100
      description = "Shared data volume"
      tags = ["data", "shared"]
    }
  ]

  volume_attachments = [
    { droplet_name = "web-1", volume_name = "data-vol" },
    { droplet_name = "web-2", volume_name = "data-vol" }
  ]

  floating_ips = [
    { droplet_name = "web-1" }
  ]

  # Enhanced firewall with better security
  enable_firewall = true
  firewall_name   = "prod-firewall"
  firewall_inbound_rules = [
    {
      protocol = "tcp"
      port_range = "22"
      source_addresses = ["203.0.113.10/32", "::1/128"] # Restrict SSH access
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

  # Load Balancer configuration
  enable_load_balancer = true
  load_balancer_name = "web-lb"
  load_balancer_forwarding_rules = [
    {
      entry_port     = 80
      entry_protocol = "http"
      target_port    = 80
      target_protocol = "http"
    },
    {
      entry_port     = 443
      entry_protocol = "https"
      target_port    = 443
      target_protocol = "https"
      # certificate_id = "your-cert-id" # Uncomment if using SSL
    }
  ]
  load_balancer_healthcheck = {
    protocol = "http"
    port     = 80
    path     = "/health"
    check_interval_seconds = 10
    response_timeout_seconds = 5
    healthy_threshold = 3
    unhealthy_threshold = 5
  }
  load_balancer_droplet_tag = "load-balancer"
}
```

## 📖 Variables

### Core Variables
| Name                | Description                                 | Type   | Default         |
|---------------------|---------------------------------------------|--------|-----------------|
| do_token            | DigitalOcean API token                      | string | n/a             |
| region              | Default region                              | string | "nyc1"          |
| environment         | Environment name for resource naming        | string | null            |
| prevent_destroy     | Prevent accidental resource destruction     | bool   | false           |
| vpc_id              | Existing VPC ID (optional)                  | string | null            |
| vpc_name            | Name for new VPC                            | string | "droplet-vpc"   |

### SSH Configuration
| Name                | Description                                 | Type   | Default         |
|---------------------|---------------------------------------------|--------|-----------------|
| create_ssh_key      | Whether to create a new SSH key             | bool   | false           |
| ssh_key_name        | Name for SSH key if created                 | string | "droplet-key"   |
| ssh_public_key      | Public key for new SSH key                  | string | ""              |
| ssh_key_fingerprints| List of existing SSH key fingerprints       | list   | []              |

### Resource Configuration
| Name                | Description                                 | Type   | Default         |
|---------------------|---------------------------------------------|--------|-----------------|
| tags                | Tags to apply to all resources              | list   | []              |
| user_data_vars      | Variables to pass to user data templates    | map    | {}              |
| default_user_data_file | Default user data file for droplets       | string | null            |
| default_user_data_template | Default user data template for droplets| string | null            |
| default_monitoring  | Enable monitoring for all droplets by default| bool  | false           |
| default_backups     | Enable backups for all droplets by default  | bool   | false           |

### Load Balancer Variables
| Name                | Description                                 | Type   | Default         |
|---------------------|---------------------------------------------|--------|-----------------|
| enable_load_balancer| Whether to create a load balancer           | bool   | false           |
| load_balancer_name  | Name for the load balancer                  | string | "droplet-lb"    |
| load_balancer_forwarding_rules | List of forwarding rules              | list   | see code        |
| load_balancer_healthcheck | Health check configuration              | object | see code        |
| load_balancer_droplet_tag | Tag for droplets to include in LB      | string | "web"           |

### Firewall Variables
| Name                | Description                                 | Type   | Default         |
|---------------------|---------------------------------------------|--------|-----------------|
| enable_firewall     | Whether to create and assign a firewall     | bool   | false           |
| firewall_name       | Name for the firewall if created            | string | "droplet-firewall"|
| firewall_inbound_rules | List of inbound firewall rules            | list   | see code        |
| firewall_outbound_rules| List of outbound firewall rules           | list   | see code        |
| existing_firewall_id| ID of an existing firewall to use           | string | null            |

### Resource Objects
| Name                | Description                                 | Type   | Default         |
|---------------------|---------------------------------------------|--------|-----------------|
| droplets            | List of droplet objects (see below)         | list   | n/a             |
| volumes             | List of volume objects (see below)          | list   | []              |
| volume_attachments  | List of volume attachment objects           | list   | []              |
| floating_ips        | List of floating IP assignment objects      | list   | []              |

## 📤 Outputs
| Name                   | Description                                 |
|------------------------|---------------------------------------------|
| droplet_ids            | IDs of all created droplets                 |
| droplet_public_ips     | Public IPv4 addresses of all droplets       |
| droplet_private_ips    | Private IPv4 addresses of all droplets      |
| droplet_status         | Status of all droplets                      |
| droplet_hostnames      | Hostnames of all created droplets           |
| droplet_tags           | Tags applied to each droplet                |
| volume_ids             | IDs of all created volumes                  |
| volume_names           | Names of all created volumes                |
| volume_attachments     | Map of droplet names to attached volumes    |
| floating_ip_addresses  | Floating IP addresses assigned to droplets  |
| ssh_key_fingerprint    | Fingerprint of the created SSH key (if any) |
| ssh_connection_strings | SSH connection strings for each droplet     |
| firewall_id            | ID of the created firewall (if any)         |
| vpc_id                 | ID of the VPC used by the droplets          |
| load_balancer_id       | ID of the created load balancer (if any)    |
| load_balancer_ip       | IP address of the load balancer (if any)    |
| load_balancer_urn      | URN of the load balancer (if any)           |
| summary                | Summary of all created resources            |

## 🔒 Security Best Practices

### Firewall Rules
- Restrict SSH access to specific IP addresses
- Use private networks for internal communication
- Implement least-privilege access principles
- Regularly review and update firewall rules

### SSH Key Management
- Use existing SSH keys when possible
- Rotate SSH keys regularly
- Store SSH keys securely
- Use key-based authentication only

### Resource Protection
- Enable `prevent_destroy` for production resources
- Use environment-based naming for better organization
- Implement proper tagging for cost allocation and security
- Use VPCs for network isolation

## 🏷️ Tagging Strategy

The module automatically adds the following tags to all resources:
- `managed-by:terraform` - Identifies Terraform-managed resources
- `module:digitalocean-droplet` - Identifies the module
- `created:YYYY-MM-DD` - Creation date
- Custom tags provided via the `tags` variable

## 🔄 Lifecycle Management

### Resource Protection
- Use `prevent_destroy = true` for production environments
- Implement proper backup strategies
- Use floating IPs for zero-downtime deployments

### Updates and Maintenance
- Use `terraform plan` before applying changes
- Test changes in non-production environments first
- Monitor resource costs and usage
- Regularly update base images and dependencies

## 🧪 Testing

### Terratest Example
```go
package test

import (
	"testing"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestTerraformModule(t *testing.T) {
	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/complete",
		NoColor:      true,
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	outputs := terraform.OutputAll(t, terraformOptions)
	assert.NotNil(t, outputs["droplet_public_ips"])
	assert.NotNil(t, outputs["summary"])
}
```

### Checkov Security Scanning
```bash
checkov -d . --framework terraform
```

## 📚 Examples

See [examples/complete/main.tf](examples/complete/main.tf) for a complete working example.

## 🔧 Troubleshooting

### Common Issues
1. **SSH Key Issues**: Ensure SSH key fingerprints are correct and keys exist in DigitalOcean
2. **Region Mismatch**: Verify all resources are in the same region or properly configured for multi-region
3. **Firewall Rules**: Check that firewall rules allow necessary traffic
4. **Load Balancer Health Checks**: Ensure health check endpoints are accessible

### Debugging
- Use `terraform plan -detailed-exitcode` for detailed planning
- Check DigitalOcean API limits and quotas
- Verify network connectivity and DNS resolution
- Review DigitalOcean console for resource status

## 📈 Performance Considerations

- Use appropriate droplet sizes for your workload
- Consider using volumes for persistent storage
- Implement proper monitoring and alerting
- Use load balancers for high availability
- Optimize firewall rules for performance

## 🔄 Migration Guide

When upgrading the module:
1. Review the changelog for breaking changes
2. Test in a non-production environment
3. Use `terraform state mv` for resource renames
4. Update variable names and types as needed
5. Review and update firewall rules

## 📄 License

This module is licensed under the MIT License. See LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## 📞 Support

For issues and questions:
1. Check the troubleshooting section
2. Review existing GitHub issues
3. Create a new issue with detailed information
4. Include terraform plan output and error messages 