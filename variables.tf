variable "cluster_name"         {
                                    description = "The name of the Vault cluster (e.g. vault-stage). This variable is used to namespace all resources created by this module."
                                    default     = "rax-vault"
}
variable "availability_zones"   {
                                    description = "The availability zones into which the EC2 Instances should be deployed. You should typically pass in one availability zone per node in the cluster_size variable. We strongly recommend against passing in only a list of availability zones, as that will run Vault in the default (and most likely public) subnets in your VPC. At least one of var.subnet_ids or var.availability_zones must be non-empty."
                                    type        = list(string)
                                    default     = []
}
variable "subnet_ids"           {
                                    description = "The subnet IDs into which the EC2 Instances should be deployed. You should typically pass in one subnet ID per node in the cluster_size variable. We strongly recommend that you run Vault in private subnets. At least one of var.subnet_ids or var.availability_zones must be non-empty."
                                    type        = list(string)
                                    default     = []
}
variable "cluster_size"         {
                                    description = "Cluser min, max and desired size"
                                    default     = 3
}
variable "termination_policies" {
                                    description = "A list of policies to decide how the instances in the auto scale group should be terminated. The allowed values are OldestInstance, NewestInstance, OldestLaunchConfiguration, ClosestToNextInstanceHour, Default."
                                    default     = "Default"
}
variable "health_check_type"    {
                                    description = "Controls how health checking is done. Must be one of EC2 or ELB."
                                    default     = "EC2"
}
variable "health_check_grace_period" {
                                    description = "Time, in seconds, after instance comes into service before checking health."
                                    default     = 300
}
variable "wait_for_capacity_timeout" {
                                    description = "A maximum duration that Terraform should wait for ASG instances to be healthy before timing out. Setting this to '0' causes Terraform to skip all Capacity Waiting behavior."
                                    default     = "10m"
}
variable "enabled_metrics"      {
                                    description = "List of autoscaling group metrics to enable."
                                    type        = list(string)
                                    default     = []
}

variable "image_id" {
                                    description = "Source AMI for instance"
}

variable "instance_type" {
                                    description = "Instance type"
                                    default = "m5.large"
}

variable "user_data" {
                                    description = "Startup script for instance"
}

variable "key_name" {
                                    description = "Default SSH key used to access the intance"
}

variable "tenancy" {
                                    description = "The tenancy of the instance. Must be one of: default or dedicated."
                                    default     = "default"
}

variable "root_volume_type" {
                                    description = "Disk type of the instance root volume"
                                    default     = "gp2"
}

variable "root_volume_size" {
                                    description = "Size of the instance root volume"
                                    default     = 50
}


variable "root_volume_delete_on_termination" {
                                    description = "Delete root volume on termination of instance"
                                    type        = list(bool)
                                    default     = true
}

variable "allowed_ssh_cidr_blocks" {
                                    description = "The port to use for SSH access"
                                    type          = list(string)
                                    default     = [null]
}

variable "ssh_port" {
                                    description = "The port to use for SSH access"
                                    default     = 22
}
variable "api_port" {
                                    description = "The port to use for Vault API calls"
                                    default     = 8200
}

variable "cluster_port" {
                                    description = "The port to use for Vault server-to-server communication"
                                    default     = 8201
}

variable "allowed_ssh_security_group_ids" {
                                    description = "Security Groups to allow SSH access from"
}

variable "allowed_api_cidr_blocks" {
                                    description = "CIDR blocks to allow API access from"
}

variable "allowed_api_security_group_ids" {
                                    description = "Security Groups to allow API access from"
}
variable "vault_egress_ports" {
                                    description = "Vault egress ports"
                                    default = "0"
}

variable "vault_egress_protocol" {
                                    description = "Vault egress protocol"
                                    default = "-1"
}

variable "enable_auto_unseal" {
                                    description = "Use KMS to automatically unseal Vault"
                                    default = 0
}

variable "access_log_bucket" {
                                    description = "Bucket used to store NLB access logs"

}

variable "cluster_tag_key" {
                                    description = "Key value for cluster name tag"
                                    default     = "Name"

}
