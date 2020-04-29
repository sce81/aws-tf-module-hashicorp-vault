resource "aws_autoscaling_group" "main" {
  name_prefix                               = var.cluster_name
  launch_configuration                      = aws_launch_configuration.main.name
  availability_zones                        = var.availability_zones
  vpc_zone_identifier                       = var.subnet_ids

  //cluster size should be static and only scaled manually
  min_size                                  = var.cluster_size
  max_size                                  = var.cluster_size
  desired_capacity                          = var.cluster_size
  
  termination_policies                      = [var.termination_policies]

  health_check_type                         = var.health_check_type
  health_check_grace_period                 = var.health_check_grace_period
  wait_for_capacity_timeout                 = var.wait_for_capacity_timeout
  enabled_metrics                           = var.enabled_metrics


  tag {
    key                         = var.cluster_tag_key
    value                       = var.cluster_name
    propagate_at_launch         = true
  }

  tag {
    key                         = "using_auto_unseal"
    value                       = element(concat(aws_iam_role_policy.vault_auto_unseal_kms.*.name, [""]), 0)
    propagate_at_launch         = true
  }
  dynamic "tag" {
    for_each                    = var.cluster_extra_tags

    content {
      key                       = tag.value.key
      value                     = tag.value.value
      propagate_at_launch       = true
    }
  }

}


resource "aws_launch_configuration" "main" {
 name_prefix                    = var.cluster_name
 image_id                       = var.image_id
 instance_type                  = var.instance_type
 user_data                      = var.user_data
 iam_instance_profile           = aws_iam_instance_profile.main.name
 key_name                       = var.key_name

 security_groups                = concat([aws_security_group.lc_security_group.id],var.additional_security_group_ids)
 placement_tenancy              = var.placement_tenancy
 associate_public_ip_address    = false

 ebs_optimized                  = var.root_volume_ebs_optimized

  root_block_device {
    volume_type                 = var.root_volume_type
    volume_size                 = var.root_volume_size
    delete_on_termination       = var.root_volume_delete_on_termination
  }
  lifecycle {
    create_before_destroy = true
  }

}


resource "aws_lb" "main" {
  name_prefix                   = var.cluster_name
  internal                      = true
  load_balancer_type            = "network"
  subnets                       = var.subnet_ids

  enable_deletion_protection    = true

  access_logs {
    bucket                      = var.access_log_bucket
    prefix                      = var.cluster_name
    enabled                     = true
  }

  tag {
    key                         = var.cluster_tag_key
    value                       = var.cluster_name
    propagate_at_launch         = true
  }

  dynamic "tag" {
    for_each                    = var.cluster_extra_tags

    content {
      key                       = tag.value.key
      value                     = tag.value.value
      propagate_at_launch       = true
    }
  }
}

resource "security_group" "api" {
 name_prefix                    = "${var.name_prefix}_api"
 description                    = "Security Group for ${var.name_prefix} API"
 vpc_id                         = var.vpc_id

 lifecycle {
     create_before_destroy = true
 }
  tags = merge(
    {
      "Name" = var.cluster_name
    },
    var.security_group_tags,
  )
}

resource "security_group_rule" "vault_api_cidr" {
 count                           = length(var.allowed_api_cidr_blocks) >= 1 ? 1 : 0
 description                     = "Vault API Access"
 type                            = "ingress"
 from_port                       = var.api_port
 to_port                         = var.api_port
 protocol                        = "tcp"
 cidr_blocks                     = element(var.allowed_api_cidr_blocks.*, count.index)
 security_group_id               = aws_security_group.api.id
}

resource "security_group_rule" "vault_api_sg" {
 count                           = length(var.allowed_api_security_group_ids) >= 1 ? 1 : 0
 description                     = "Vault API Access"
 type                            = "ingress"
 from_port                       = var.api_port
 to_port                         = var.api_port
 protocol                        = "tcp"
 cidr_blocks                     = element(var.allowed_api_security_group_ids.*, count.index)
 security_group_id               = aws_security_group.api.id
}


resource "security_group" "main" {
 name_prefix                    = var.name_prefix
 description                    = "Security Group for ${var.name_prefix}"
 vpc_id                         = var.vpc_id

 lifecycle {
     create_before_destroy = true
 }
  tags = merge(
    {
      "Name" = var.cluster_name
    },
    var.security_group_tags,
  )
}

resource "security_group_rule" "ssh_cidr" {
 count                           = length(var.allowed_ssh_cidr_blocks) >= 1 ? 1 : 0
 description                     = "SSH from ${element(var.allowed_ssh_cidr_blocks.*, count.index)}"
 type                            = "ingress"
 from_port                       = var.ssh_port
 to_port                         = var.ssh_port
 protocol                        = "tcp"
 cidr_blocks                     = element(var.allowed_ssh_cidr_blocks.*, count.index)
 security_group_id               = aws_security_group.main.id
}

resource "security_group_rule" "ssh_security_group" {
 count                           = length(var.allowed_ssh_security_group_ids) >= 1 ? 1 : 0
 description                     = "SSH from Security Group"
 type                            = "ingress"
 from_port                       = var.ssh_port
 to_port                         = var.ssh_port
 protocol                        = "tcp"
 source_security_group_id        = element(var.allowed_ssh_security_group_ids, count.index)
 security_group_id               = aws_security_group.main.id
}

resource "security_group_rule" "vault_internal_ingress" {
 description                     = "Vault Internal Ingress"
 type                            = "ingress"
 from_port                       = var.cluster_port
 to_port                         = var.cluster_port
 protocol                        = "tcp"
 self                            = true
 security_group_id               = aws_security_group.main.id
}

resource "security_group_rule" "vault_internal_egress" {
 description                     = "Vault Internal Egress"
 type                            = "egress"
 from_port                       = var.cluster_port
 to_port                         = var.cluster_port
 protocol                        = "tcp"
 self                            = true
 security_group_id               = aws_security_group.main.id
}

resource "security_group_rule" "global_egress" {
  count                         = length(var.vault_egress_ports)
  type                          = "egress"
  from_port                     = element(var.vault_egress_ports.*, count.index)
  to_port                       = element(var.vault_egress_ports.*, count.index)
  protocol                      = element(var.vault_egress_protocol.*, count.index)
  cidr_blocks                   = element(var.vault_egress_cidr_blocks.*, count.index)

  security_group_id             = aws_security_group.main.id
}

resource "instance_profile" "main" {
  name_prefix                   = var.cluster_name
  path                          = var.instance_profile_path
  role                          = aws_iam_role.instance_role.name

  lifecycle {
      propagate_at_launch = true
  }
}

resource "instance_role" "main" {
  name_prefix                   = var.cluster_name
  assume_role_policy            = data.aws_iam_policy_document.instance_role.json

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "instance_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "vault_auto_unseal_kms" {
  count = var.enable_auto_unseal ? 1 : 0

  statement {
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey",
    ]

    resources = [var.auto_unseal_kms_key_arn]
  }
}

resource "aws_iam_role_policy" "vault_auto_unseal_kms" {
  count = var.enable_auto_unseal ? 1 : 0
  name  = "vault_auto_unseal_kms"
  role  = aws_iam_role.instance_role.id
  policy = element(concat(data.aws_iam_policy_document.vault_auto_unseal_kms.*.json,[""],),0,)


  lifecycle {
    create_before_destroy = true
  }
}