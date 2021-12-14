packer {
  required_version = ">= 1.5.4"
}

variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

variable "consul_version" {
  type    = string
  default = "1.10.4"
}

variable "download_url" {
  type    = string
  default = "${env("CONSUL_DOWNLOAD_URL")}"
}

data "amazon-ami" "amzn2-ami" {
  filters = {
    architecture                       = "x86_64"
    "block-device-mapping.volume-type" = "gp2"
    name                               = "*amzn2-ami-hvm-*-x86_64-gp2"
    root-device-type                   = "ebs"
    virtualization-type                = "hvm"
  }
  most_recent = true
  owners      = ["amazon"]
  region      = "${var.aws_region}"
}

data "amazon-ami" "ubuntu16" {
  filters = {
    architecture                       = "x86_64"
    "block-device-mapping.volume-type" = "gp2"
    name                               = "*ubuntu-xenial-16.04-amd64-server-*"
    root-device-type                   = "ebs"
    virtualization-type                = "hvm"
  }
  most_recent = true
  owners      = ["099720109477"]
  region      = "${var.aws_region}"
}

data "amazon-ami" "ubuntu18" {
  filters = {
    architecture                       = "x86_64"
    "block-device-mapping.volume-type" = "gp2"
    name                               = "ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"
    root-device-type                   = "ebs"
    virtualization-type                = "hvm"
  }
  most_recent = true
  owners      = ["099720109477"]
  region      = "${var.aws_region}"
}

data "amazon-ami" "ubuntu20" {
  filters = {
    architecture                       = "x86_64"
    "block-device-mapping.volume-type" = "gp2"
    name                               = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
    root-device-type                   = "ebs"
    virtualization-type                = "hvm"
  }
  most_recent = true
  owners      = ["099720109477"]
  region      = "${var.aws_region}"
}

# 1 error occurred upgrading the following block:
# unhandled "clean_resource_name" call:
# there is no way to automatically upgrade the "clean_resource_name" call.
# Please manually upgrade to use custom validation rules, `replace(string, substring, replacement)` or `regex_replace(string, substring, replacement)`
# Visit https://packer.io/docs/templates/hcl_templates/variables#custom-validation-rules , https://www.packer.io/docs/templates/hcl_templates/functions/string/replace or https://www.packer.io/docs/templates/hcl_templates/functions/string/regex_replace for more infos.

source "amazon-ebs" "amazon-linux-2-ami" {
  ami_description = "An Amazon Linux 2 AMI that has Consul installed."
  ami_name        = "consul-amazon-linux-2-${uuidv4()}"
  instance_type   = "t2.micro"
  region          = "${var.aws_region}"
  source_ami      = "${data.amazon-ami.amzn2-ami.id}"
  ssh_username    = "ec2-user"
}

# 1 error occurred upgrading the following block:
# unhandled "clean_resource_name" call:
# there is no way to automatically upgrade the "clean_resource_name" call.
# Please manually upgrade to use custom validation rules, `replace(string, substring, replacement)` or `regex_replace(string, substring, replacement)`
# Visit https://packer.io/docs/templates/hcl_templates/variables#custom-validation-rules , https://www.packer.io/docs/templates/hcl_templates/functions/string/replace or https://www.packer.io/docs/templates/hcl_templates/functions/string/regex_replace for more infos.

source "amazon-ebs" "ubuntu16-ami" {
  ami_description = "An Ubuntu 16.04 AMI that has Consul installed."
  ami_name        = "consul-ubuntu-${uuidv4()}"
  instance_type   = "t2.micro"
  region          = "${var.aws_region}"
  source_ami      = "${data.amazon-ami.ubuntu16.id}"
  ssh_username    = "ubuntu"
}

# 1 error occurred upgrading the following block:
# unhandled "clean_resource_name" call:
# there is no way to automatically upgrade the "clean_resource_name" call.
# Please manually upgrade to use custom validation rules, `replace(string, substring, replacement)` or `regex_replace(string, substring, replacement)`
# Visit https://packer.io/docs/templates/hcl_templates/variables#custom-validation-rules , https://www.packer.io/docs/templates/hcl_templates/functions/string/replace or https://www.packer.io/docs/templates/hcl_templates/functions/string/regex_replace for more infos.

source "amazon-ebs" "ubuntu18-ami" {
  ami_description             = "An Ubuntu 18.04 AMI that has Consul installed."
  ami_name                    = "consul-ubuntu-${uuidv4()}"
  associate_public_ip_address = true
  instance_type               = "t2.micro"
  region                      = "${var.aws_region}"
  source_ami                  = "${data.amazon-ami.ubuntu18.id}"
  ssh_username                = "ubuntu"
}

# 1 error occurred upgrading the following block:
# unhandled "clean_resource_name" call:
# there is no way to automatically upgrade the "clean_resource_name" call.
# Please manually upgrade to use custom validation rules, `replace(string, substring, replacement)` or `regex_replace(string, substring, replacement)`
# Visit https://packer.io/docs/templates/hcl_templates/variables#custom-validation-rules , https://www.packer.io/docs/templates/hcl_templates/functions/string/replace or https://www.packer.io/docs/templates/hcl_templates/functions/string/regex_replace for more infos.

source "amazon-ebs" "ubuntu20-ami" {
  ami_description             = "An Ubuntu 20.04 AMI that has Consul installed."
  ami_name                    = "consul-ubuntu-${uuidv4()}"
  associate_public_ip_address = true
  instance_type               = "t2.micro"
  region                      = "${var.aws_region}"
  source_ami                  = "${data.amazon-ami.ubuntu20.id}"
  ssh_username                = "ubuntu"
}

build {
  sources = ["source.amazon-ebs.amazon-linux-2-ami", "source.amazon-ebs.ubuntu16-ami", "source.amazon-ebs.ubuntu18-ami", "source.amazon-ebs.ubuntu20-ami"]

  provisioner "shell" {
    inline = ["mkdir -p /tmp/terraform-aws-consul/modules"]
  }

  provisioner "file" {
    destination  = "/tmp/terraform-aws-consul/modules"
    pause_before = "30s"
    source       = "${path.root}/../../modules/"
  }

  provisioner "shell" {
    inline       = ["if test -n \"${var.download_url}\"; then", " /tmp/terraform-aws-consul/modules/install-consul/install-consul --download-url ${var.download_url};", "else", " /tmp/terraform-aws-consul/modules/install-consul/install-consul --version ${var.consul_version};", "fi"]
    pause_before = "30s"
  }

  provisioner "shell" {
    inline       = ["/tmp/terraform-aws-consul/modules/install-dnsmasq/install-dnsmasq"]
    only         = ["ubuntu16-ami", "amazon-linux-2-ami"]
    pause_before = "30s"
  }

  provisioner "shell" {
    inline       = ["/tmp/terraform-aws-consul/modules/setup-systemd-resolved/setup-systemd-resolved"]
    only         = ["ubuntu18-ami", "ubuntu20-ami"]
    pause_before = "30s"
  }

}
