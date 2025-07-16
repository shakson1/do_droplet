variable "do_token" {
  description = "DigitalOcean API token."
  type        = string
  sensitive   = true
}

variable "region" {
  description = "Default region for resources."
  type        = string
  default     = "nyc1"
  validation {
    condition = contains([
      "nyc1", "nyc2", "nyc3", "ams3", "sfo2", "sfo3", "sgp1", "lon1", "fra1", "tor1", "blr1", "syd1", "atl1"
    ], var.region)
    error_message = "Region must be a valid DigitalOcean region: nyc1, nyc2, nyc3, ams3, sfo2, sfo3, sgp1, lon1, fra1, tor1, blr1, syd1, atl1."
  }
}

variable "vpc_id" {
  description = "Existing VPC ID to use. If not set, a new VPC will be created."
  type        = string
  default     = null
}

variable "vpc_name" {
  description = "Name for the VPC if created."
  type        = string
  default     = "droplet-vpc"
}

variable "create_ssh_key" {
  description = "Whether to create a new SSH key."
  type        = bool
  default     = false
}

variable "ssh_key_name" {
  description = "Name for the SSH key if created."
  type        = string
  default     = "droplet-key"
}

variable "ssh_public_key" {
  description = "Public key to use if creating a new SSH key."
  type        = string
  default     = ""
}

variable "ssh_key_fingerprints" {
  description = "List of existing SSH key fingerprints to inject into droplets."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources (VPC, volumes, floating IPs, etc)."
  type        = list(string)
  default     = []
}

variable "default_user_data_file" {
  description = "Default user data file to use for droplets if not specified in the droplet object."
  type        = string
  default     = null
}

variable "default_user_data_template" {
  description = "Default user data template file to use for droplets if not specified in the droplet object."
  type        = string
  default     = null
}

variable "default_monitoring" {
  description = "Enable monitoring for all droplets by default."
  type        = bool
  default     = false
}

variable "default_backups" {
  description = "Enable backups for all droplets by default."
  type        = bool
  default     = false
}

variable "droplets" {
  description = <<EOT
List of droplet objects. Each object supports:
- name (string, required)
- region (string, optional)
- size (string, required)
- image (string, required)
- tags (list(string), optional)
- user_data (string, optional, inline)
- user_data_file (string, optional, path to file)
- user_data_template (string, optional, path to template file)
- monitoring (bool, optional)
- backups (bool, optional)
EOT
  type = list(object({
    name      = string
    region    = optional(string)
    size      = string
    image     = string
    tags      = optional(list(string))
    user_data = optional(string)
    user_data_file = optional(string)
    user_data_template = optional(string)
    monitoring = optional(bool)
    backups    = optional(bool)
  }))
  validation {
    condition = alltrue([
      for d in var.droplets :
        length(trimspace(d.name)) > 0 &&
        length(trimspace(d.size)) > 0 &&
        length(trimspace(d.image)) > 0
    ])
    error_message = "Each droplet must have a non-empty name, size, and image."
  }
  validation {
    condition = alltrue([
      for d in var.droplets :
        d.region == null || contains([
          "nyc1", "nyc2", "nyc3", "ams3", "sfo2", "sfo3", "sgp1", "lon1", "fra1", "tor1", "blr1", "syd1", "atl1"
        ], d.region)
    ])
    error_message = "If set, droplet region must be a valid DigitalOcean region."
  }
  validation {
    condition = alltrue([
      for d in var.droplets :
        contains([
          "s-1vcpu-512mb-10gb", "s-1vcpu-1gb", "s-2vcpu-2gb", "s-2vcpu-4gb", "s-4vcpu-8gb", "s-8vcpu-16gb",
          "c-2", "c-4", "c-8", "c-16", "c-32", "c-48",
          "g-2vcpu-8gb", "g-4vcpu-16gb", "g-8vcpu-32gb", "g-16vcpu-64gb", "g-32vcpu-128gb", "g-40vcpu-160gb",
          "m-2vcpu-16gb", "m-4vcpu-32gb", "m-8vcpu-64gb", "m-16vcpu-128gb", "m-24vcpu-192gb", "m-32vcpu-256gb",
          "so-2vcpu-16gb", "so-4vcpu-32gb", "so-8vcpu-64gb", "so-16vcpu-128gb", "so-24vcpu-192gb", "so-32vcpu-256gb"
        ], d.size)
    ])
    error_message = "Each droplet size must be a valid DigitalOcean size slug. See https://www.digitalocean.com/pricing/droplets for options."
  }
}

variable "volumes" {
  description = <<EOT
List of volume objects. Each object supports:
- name (string, required)
- region (string, optional)
- size (number, required, in GB)
- description (string, optional)
- filesystem_type (string, optional)
- snapshot_id (string, optional)
EOT
  type = list(object({
    name            = string
    region          = optional(string)
    size            = number
    description     = optional(string)
    filesystem_type = optional(string)
    snapshot_id     = optional(string)
  }))
  default = []
  validation {
    condition = alltrue([
      for v in var.volumes :
        length(trimspace(v.name)) > 0 &&
        v.size >= 1
    ])
    error_message = "Each volume must have a non-empty name and a size of at least 1 GB."
  }
  validation {
    condition = alltrue([
      for v in var.volumes :
        v.region == null || contains([
          "nyc1", "nyc2", "nyc3", "ams3", "sfo2", "sfo3", "sgp1", "lon1", "fra1", "tor1", "blr1", "syd1", "atl1"
        ], v.region)
    ])
    error_message = "If set, volume region must be a valid DigitalOcean region."
  }
}

variable "volume_attachments" {
  description = <<EOT
List of volume attachment objects. Each object supports:
- droplet_name (string, required)
- volume_name (string, required)
EOT
  type = list(object({
    droplet_name = string
    volume_name  = string
  }))
  default = []
  # Cross-variable validation removed for Terraform compatibility
}

variable "floating_ips" {
  description = <<EOT
List of floating IP assignment objects. Each object supports:
- droplet_name (string, required)
EOT
  type = list(object({
    droplet_name = string
  }))
  default = []
  # Cross-variable validation removed for Terraform compatibility
}

variable "enable_firewall" {
  description = "Whether to create and assign a DigitalOcean firewall to the droplets."
  type        = bool
  default     = false
}

variable "firewall_name" {
  description = "Name for the firewall if created."
  type        = string
  default     = "droplet-firewall"
}

variable "firewall_inbound_rules" {
  description = "List of inbound rules for the firewall (see DigitalOcean provider docs)."
  type        = list(any)
  default     = [
    {
      protocol = "tcp"
      port_range = "22"
      source_addresses = ["0.0.0.0/0", "::/0"]
    }
  ]
}

variable "firewall_outbound_rules" {
  description = "List of outbound rules for the firewall (see DigitalOcean provider docs)."
  type        = list(object({
    protocol                = string
    port_range              = optional(string)
    destination_addresses   = optional(list(string))
    destination_tags        = optional(list(string))
    destination_droplet_ids = optional(list(string))
    destination_load_balancer_uids = optional(list(string))
    destination_kubernetes_ids     = optional(list(string))
  }))
  default     = [
    {
      protocol = "icmp"
      port_range = null
      destination_addresses = ["0.0.0.0/0", "::/0"]
      destination_tags = null
      destination_droplet_ids = null
      destination_load_balancer_uids = null
      destination_kubernetes_ids = null
    },
    {
      protocol = "tcp"
      port_range = "all"
      destination_addresses = ["0.0.0.0/0", "::/0"]
      destination_tags = null
      destination_droplet_ids = null
      destination_load_balancer_uids = null
      destination_kubernetes_ids = null
    },
    {
      protocol = "udp"
      port_range = "all"
      destination_addresses = ["0.0.0.0/0", "::/0"]
      destination_tags = null
      destination_droplet_ids = null
      destination_load_balancer_uids = null
      destination_kubernetes_ids = null
    }
  ]
}

variable "existing_firewall_id" {
  description = "ID of an existing DigitalOcean firewall to assign to the droplets. If set, no new firewall will be created."
  type        = string
  default     = null
} 