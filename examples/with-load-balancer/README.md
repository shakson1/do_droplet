# Load Balancer Example

This example demonstrates a production-ready high availability setup with multiple droplets behind a load balancer.

## What This Example Creates

- 3 Droplets (s-2vcpu-4gb Ubuntu 22.04) with monitoring and backups
- 1 Load Balancer with health checks
- 1 Firewall with restricted SSH access
- 1 VPC (automatically created)

## Architecture

```
Internet
   |
   v
Load Balancer (HTTP/HTTPS)
   |
   +-- web-1 (Droplet)
   +-- web-2 (Droplet)
   +-- web-3 (Droplet)
```

## Features

- **High Availability**: Traffic distributed across 3 droplets
- **Health Checks**: Automatic removal of unhealthy droplets
- **Security**: Firewall rules with restricted SSH access
- **Monitoring**: DigitalOcean monitoring enabled
- **Backups**: Automated daily backups
- **Protection**: `prevent_destroy` enabled

## Prerequisites

- DigitalOcean API token
- SSH key already added to your DigitalOcean account
- Your public IP address for SSH access

## Usage

1. Copy the example tfvars file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your values:
   - Add your DigitalOcean API token
   - Add your SSH key fingerprint(s)
   - Add your allowed SSH IP addresses

3. Initialize and apply:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. Get the load balancer IP:
   ```bash
   terraform output load_balancer_ip
   ```

5. Point your domain to the load balancer IP and test:
   ```bash
   curl http://<load-balancer-ip>/health
   ```

## Important Notes

- The load balancer expects a `/health` endpoint on port 80
- Ensure your application responds to health checks
- SSH access is restricted to IPs specified in `allowed_ssh_ips`
- `prevent_destroy` is enabled to prevent accidental deletion

## Clean Up

**Warning**: Resources have `prevent_destroy` enabled. You'll need to:

1. Disable prevent_destroy in the configuration
2. Apply the change
3. Then destroy:
   ```bash
   terraform destroy
   ```

## Estimated Cost

- 3 Droplets: ~$36/month (s-2vcpu-4gb × 3)
- Load Balancer: ~$12/month
- Backups: ~$7/month (20% of droplet cost)
- Total: ~$55/month

## Monitoring

Enable monitoring alerts in your DigitalOcean account:
- CPU usage > 80%
- Memory usage > 80%
- Disk usage > 80%
- Load balancer unhealthy droplets

## Next Steps

- Configure SSL certificate for HTTPS
- Add volumes for persistent storage
- Set up automated deployments
- Configure monitoring and alerting
- Implement auto-scaling based on load

