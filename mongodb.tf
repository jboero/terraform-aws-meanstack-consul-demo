resource "aws_iam_user" "mongodb" {
  count = "${var.mongodbservers}"

  name       = "${var.namespace}-mongodb-${count.index}"
  path = "/${var.namespace}/"
}

resource "aws_iam_access_key" "mongodb" {
  count = "${var.mongodbservers}"
  user  = "${element(aws_iam_user.mongodb.*.name, count.index)}"
}

data "template_file" "mongodb_iam_policy" {
  count    = "${var.mongodbservers}"
  template = "${file("${path.module}/templates/policies/iam_policy.json.tpl")}"

  vars {
    identity          = "${element(aws_iam_user.mongodb.*.name, count.index)}"
    region            = "${var.region}"
    owner_id          = "${aws_security_group.consuldemo.owner_id}"
    ami_id            = "${data.aws_ami.ubuntu.id}"
    subnet_id         = "${element(aws_subnet.consuldemo.*.id, count.index)}"
    security_group_id = "${aws_security_group.consuldemo.id}"
  }
}

# Create a limited policy for this user - this policy grants permission for the
# user to do incredibly limited things in the environment, such as launching a
# specific instance provided it has their authorization tag, deleting instances
# they have created, and describing instance data.
resource "aws_iam_user_policy" "mongodb" {
  count  = "${var.mongodbservers}"
 name       = "${var.namespace}-mongodb-${count.index}"
  user   = "${element(aws_iam_user.mongodb.*.name, count.index)}"
  policy = "${element(data.template_file.mongodb_iam_policy.*.rendered, count.index)}"
}

data "template_file" "mongodb" {
  count = "${var.mongodbservers}"

  template = "${join("\n", list(
    file("${path.module}/templates/shared/base.sh"),
    file("${path.module}/templates/shared/docker.sh"),

    file("${path.module}/templates/mongodb/user.sh"),
    file("${path.module}/templates/mongodb/consul.sh"),
    file("${path.module}/templates/mongodb/vault.sh"),
    file("${path.module}/templates/mongodb/postgres.sh"),
    file("${path.module}/templates/mongodb/terraform.sh"),
    file("${path.module}/templates/mongodb/tools.sh"),
    file("${path.module}/templates/mongodb/nomad.sh"),
    file("${path.module}/templates/mongodb/webterminal.sh"),
    file("${path.module}/templates/mongodb/connectdemo.sh"),
  ))}"

  vars {
    namespace = "${var.namespace}"
    node_name = "${element(aws_iam_user.mongodb.*.name, count.index)}"
    me_ca     = "${tls_self_signed_cert.root.cert_pem}"
    me_cert   = "${element(tls_locally_signed_cert.mongodb.*.cert_pem, count.index)}"
    me_key    = "${element(tls_private_key.mongodb.*.private_key_pem, count.index)}"

    # User
    demo_username = "${var.demo_username}"
    demo_password = "${var.demo_password}"
    identity          = "${element(aws_iam_user.mongodb.*.name, count.index)}"

    # Consul
    consul_url            = "${var.consul_url}"
    consul_gossip_key     = "${base64encode(random_id.consul_gossip_key.hex)}"
    consul_join_tag_key   = "ConsulJoin"
    consul_join_tag_value = "${local.consul_join_tag_value}"

    # Terraform
    terraform_url     = "${var.terraform_url}"
    region            = "${var.region}"
    ami_id            = "${data.aws_ami.ubuntu.id}"
    subnet_id         = "${element(aws_subnet.consuldemo.*.id, count.index)}"
    security_group_id = "${aws_security_group.consuldemo.id}"
    access_key        = "${element(aws_iam_access_key.mongodb.*.id, count.index)}"
    secret_key        = "${element(aws_iam_access_key.mongodb.*.secret, count.index)}"

    # Tools
    consul_template_url = "${var.consul_template_url}"
    envconsul_url       = "${var.envconsul_url}"
    packer_url          = "${var.packer_url}"
    sentinel_url        = "${var.sentinel_url}"

    # Nomad
    nomad_url = "${var.nomad_url}"

    # Vault
    vault_url = "${var.vault_url}"
  }
}

# Gzip cloud-init config
data "template_cloudinit_config" "mongodb" {
  count = "${var.mongodbservers}"

  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = "${element(data.template_file.mongodb.*.rendered, count.index)}"
  }
}

# IAM
resource "aws_iam_role" "mongodb" {
  count              = "${var.mongodbservers}"
 name       = "${var.namespace}-mongodb-${count.index}"
  assume_role_policy = "${file("${path.module}/templates/policies/assume-role.json")}"
}

resource "aws_iam_policy" "mongodb" {
  count       = "${var.mongodbservers}"
  name       = "${var.namespace}-mongodb-${count.index}"
  description = "Allows user ${element(aws_iam_user.mongodb.*.name, count.index)} to use their mongodb server."
  policy      = "${element(data.template_file.mongodb_iam_policy.*.rendered, count.index)}"
}

resource "aws_iam_policy_attachment" "mongodb" {
  count      = "${var.mongodbservers}"
  name       = "${var.namespace}-mongodb-${count.index}"
  roles      = ["${element(aws_iam_role.mongodb.*.name, count.index)}"]
  policy_arn = "${element(aws_iam_policy.mongodb.*.arn, count.index)}"
}

resource "aws_iam_instance_profile" "mongodb" {
  count = "${var.mongodbservers}"
  name       = "${var.namespace}-mongodb-${count.index}"
  role  = "${element(aws_iam_role.mongodb.*.name, count.index)}"
}

resource "aws_instance" "mongodb" {
  count = "${var.mongodbservers}"

  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.medium"
  key_name      = "${aws_key_pair.consuldemo.id}"

  subnet_id              = "${element(aws_subnet.consuldemo.*.id, count.index)}"
  iam_instance_profile   = "${element(aws_iam_instance_profile.mongodb.*.name, count.index)}"
  vpc_security_group_ids = ["${aws_security_group.consuldemo.id}"]

  tags {
    Name       = "${var.namespace}-mongodb-${count.index}"
    owner      = "${var.owner}"
    created-by = "${var.created-by}"
  }

  user_data = "${element(data.template_cloudinit_config.mongodb.*.rendered, count.index)}"

  provisioner "file" {
    source      = "${path.module}/templates/connectdemo/"
    destination = "/tmp/"

    connection {
      type     = "ssh"
      user     = "${var.demo_username}"
      password = "${var.demo_password}"
    }
  }
}

output "mongodb server" {
  value = ["${aws_instance.mongodb.*.public_ip}"]
}

output "mongodb_consul_ui" {
  value = "${formatlist("http://%s:8500/", aws_instance.mongodb.*.public_ip,)}"
}

