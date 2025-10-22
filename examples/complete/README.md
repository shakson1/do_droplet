# Complete Example

This example demonstrates all features of the DigitalOcean Droplet module, including:

- Multiple droplets across different regions
- Block storage volumes with attachments
- Floating IPs
- Custom firewall rules
- Load balancer with SSL support
- User data templates
- Monitoring and backups

## What This Example Creates

- 3 Droplets (web-1, web-2, db-1) in different regions
- 2 Block Storage Volumes (100GB and 200GB)
- 2 Floating IPs
- 1 Firewall with custom rules
- 1 Load Balancer
- 1 VPC

## Prerequisites

- DigitalOcean API token
- SSH key already added to your DigitalOcean account

## Usage

1. Copy the example tfvars file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your actual values

3. Review the cloud-init templates:
   - `cloud-init-web1.tpl` - Template for web-1 droplet
   - `cloud-init-default.tpl` - Default template for all droplets

4. Initialize and apply:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

5. View outputs:
   ```bash
   terraform output
   ```

## Features Demonstrated

### Multi-Region Deployment
Droplets are deployed across multiple regions (nyc1, nyc3, sfo3) for geographic distribution.

### User Data Templating
Different user data options:
- Template files with variables
- Static user data files
- Inline user data

### Volume Management
Block storage volumes with automatic attachment to droplets.

### Network Configuration
- VPC for private networking
- Floating IPs for public access
- Firewall rules for security

### Load Balancing
Load balancer with:
- HTTP and HTTPS forwarding rules
- Custom health checks
- Automatic droplet discovery via tags

## Clean Up

```bash
terraform destroy
```

## Estimated Cost

- 3 Droplets: ~$30/month
- 2 Volumes: ~$20/month (300GB total)
- 2 Floating IPs: Free (when attached)
- Load Balancer: ~$12/month
- Backups: ~$6/month
- Total: ~$68/month

## Customization

This example is highly customizable. You can:
- Add/remove droplets
- Change droplet sizes and images
- Modify firewall rules
- Add more volumes
- Adjust load balancer settings

See the [main README](../../README.md) for all available options.

