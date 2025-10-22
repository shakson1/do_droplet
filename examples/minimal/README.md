# Minimal Example

This example demonstrates the minimal configuration needed to deploy a single DigitalOcean droplet using this module.

## What This Example Creates

- 1 Droplet (s-1vcpu-1gb Ubuntu 22.04)
- 1 VPC (automatically created)

## Prerequisites

- DigitalOcean API token
- SSH key already added to your DigitalOcean account

## Usage

1. Copy the example tfvars file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your values:
   - Add your DigitalOcean API token
   - Add your SSH key fingerprint(s)

3. Initialize and apply:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. Get the droplet IP:
   ```bash
   terraform output droplet_ip
   ```

5. Connect to your droplet:
   ```bash
   terraform output -raw ssh_command
   # Then run the command shown
   ```

## Clean Up

```bash
terraform destroy
```

## Estimated Cost

- Droplet: ~$6/month (s-1vcpu-1gb)
- Total: ~$6/month

## Next Steps

- See [complete example](../complete/) for more advanced features
- See [with-load-balancer example](../with-load-balancer/) for high availability setup

