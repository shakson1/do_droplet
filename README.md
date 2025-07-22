# DigitalOcean Droplet Production Module

Deploy production-ready DigitalOcean Droplets with volume attachment, floating IPs, SSH configuration, firewalls, monitoring, backups, user data templating, and more.

## Features
- Multiple droplets (cluster or single)
- Volume creation and attachment (multiple volumes per droplet)
- Floating/static IPs (DigitalOcean reserved IPs)
- SSH key management (create or use existing)
- VPC support (create or use existing)
- All droplet options (size, image, region, tags, user data, monitoring, backups, etc)
- User data templating (inline, file, or template per droplet or global)
- Module-level and resource-level tags
- Optional DigitalOcean firewall (custom rules, auto-assignment)
- Comprehensive outputs (hostnames, IPs, SSH strings, volume info, firewall, VPC, etc)
- Robust input validation and defaults

## Prerequisites
- DigitalOcean API token with write permissions
- Terraform >= 1.3.0
- (Optional) Existing SSH key fingerprints or public key for new key

## Usage
```hcl
module "doks_droplets" {
  source     = "<YOUR_GITHUB_OR_REGISTRY_PATH>"
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
      source_addresses = ["0.0.0.0/0", "::/0"]
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
```

## Variables
| Name                | Description                                 | Type   | Default         |
|---------------------|---------------------------------------------|--------|-----------------|
| do_token            | DigitalOcean API token                      | string | n/a             |
| region              | Default region                              | string | "nyc1"          |
| vpc_id              | Existing VPC ID (optional)                  | string | null            |
| vpc_name            | Name for new VPC                            | string | "droplet-vpc"   |
| create_ssh_key      | Whether to create a new SSH key             | bool   | false           |
| ssh_key_name        | Name for SSH key if created                 | string | "droplet-key"   |
| ssh_public_key      | Public key for new SSH key                  | string | ""              |
| ssh_key_fingerprints| List of existing SSH key fingerprints       | list   | []              |
| tags                | Tags to apply to all resources              | list   | []              |
| default_user_data_file | Default user data file for droplets       | string | null            |
| default_user_data_template | Default user data template for droplets| string | null            |
| default_monitoring  | Enable monitoring for all droplets by default| bool  | false           |
| default_backups     | Enable backups for all droplets by default  | bool   | false           |
| droplets            | List of droplet objects (see above)         | list   | n/a             |
| volumes             | List of volume objects (see above)          | list   | []              |
| volume_attachments  | List of volume attachment objects           | list   | []              |
| floating_ips        | List of floating IP assignment objects      | list   | []              |
| enable_firewall     | Whether to create and assign a firewall     | bool   | false           |
| firewall_name       | Name for the firewall if created            | string | "droplet-firewall"|
| firewall_inbound_rules | List of inbound firewall rules            | list   | see code        |
| firewall_outbound_rules| List of outbound firewall rules           | list   | see code        |
| existing_firewall_id| ID of an existing firewall to use           | string | null            |

## Outputs
| Name                   | Description                                 |
|------------------------|---------------------------------------------|
| droplet_ids            | IDs of all created droplets                 |
| droplet_public_ips     | Public IPv4 addresses of all droplets       |
| droplet_private_ips    | Private IPv4 addresses of all droplets      |
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

## Example
See [examples/complete/main.tf](examples/complete/main.tf)

## Tips & Best Practices
- Use remote state for production deployments.
- Use SSH key fingerprints for existing keys, or let the module create a new key.
- Use user data templates for cloud-init or custom provisioning.
- Use tags for cost allocation, automation, and organization.
- Review DigitalOcean limits and pricing for droplets, volumes, and IPs.
- Use firewall rules to restrict access to only trusted sources.

## Upgrading the Module

When upgrading the module, especially if resources are renamed or restructured, use the `terraform state mv` command to avoid resource recreation. For example:

```sh
terraform state mv 'module.old_resource' 'module.new_resource'
```

Refer to the [Terraform documentation on state management](https://developer.hashicorp.com/terraform/cli/state/move) for more details.

## Remote State Example

For production deployments, use a remote state backend to store your Terraform state securely and enable team collaboration. Example using DigitalOcean Spaces:

```hcl
terraform {
  backend "s3" {
    endpoint   = "https://nyc3.digitaloceanspaces.com"
    bucket     = "your-terraform-state-bucket"
    key        = "do-droplet/terraform.tfstate"
    region     = "us-east-1"
    access_key = "${var.spaces_access_key}"
    secret_key = "${var.spaces_secret_key}"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    force_path_style           = true
  }
}
```

See [DigitalOcean Spaces as Terraform Remote State Backend](https://docs.digitalocean.com/reference/terraform/how-to/store-state-in-spaces/) for more details.

## Automated Testing

For infrastructure testing, consider using [Terratest](https://terratest.gruntwork.io/) for integration tests and [Checkov](https://www.checkov.io/) for static security and compliance checks.

Example Terratest usage (Go):
```sh
go test -v ./test
```

Example Checkov usage:
```sh
checkov -d .
```

Add your test cases in a `test/` directory at the root of the repo.

--- 