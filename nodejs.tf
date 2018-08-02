resource "aws_iam_user" "nodejs" {
  count = "${var.nodejsservers}"

  name = "${var.namespace}-${element(var.animals, count.index)}--nodejs"
  path = "/${var.namespace}/"
}

resource "aws_iam_access_key" "nodejs" {
  count = "${var.nodejsservers}"
  user  = "${element(aws_iam_user.nodejs.*.name, count.index)}"
}

data "template_file" "nodejs_iam_policy" {
  count    = "${var.nodejsservers}"
  template = "${file("${path.module}/templates/policies/iam_policy.json.tpl")}"

  vars {
    identity          = "${element(aws_iam_user.nodejs.*.name, count.index)}"
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
resource "aws_iam_user_policy" "nodejs" {
  count  = "${var.nodejsservers}"
  name   = "policy-${element(aws_iam_user.nodejs.*.name, count.index)}"
  user   = "${element(aws_iam_user.nodejs.*.name, count.index)}"
  policy = "${element(data.template_file.nodejs_iam_policy.*.rendered, count.index)}"
}

data "template_file" "nodejs" {
  count = "${var.nodejsservers}"

  template = "${join("\n", list(
    file("${path.module}/templates/shared/base.sh"),
    file("${path.module}/templates/shared/docker.sh"),

    file("${path.module}/templates/nodejs/user.sh"),
    file("${path.module}/templates/nodejs/consul.sh"),
    file("${path.module}/templates/nodejs/vault.sh"),
    file("${path.module}/templates/nodejs/postgres.sh"),
    file("${path.module}/templates/nodejs/terraform.sh"),
    file("${path.module}/templates/nodejs/tools.sh"),
    file("${path.module}/templates/nodejs/nomad.sh"),
    file("${path.module}/templates/nodejs/webterminal.sh"),
    file("${path.module}/templates/shared/connectdemo.sh"),
    file("${path.module}/templates/shared/cleanup.sh"),
  ))}"

  vars {
    namespace = "${var.namespace}"
    node_name = "${element(aws_iam_user.nodejs.*.name, count.index)}"
    me_ca     = "${tls_self_signed_cert.root.cert_pem}"
    me_cert   = "${element(tls_locally_signed_cert.nodejs.*.cert_pem, count.index)}"
    me_key    = "${element(tls_private_key.nodejs.*.private_key_pem, count.index)}"

    # User
    demo_username = "${var.demo_username}"
    demo_password = "${var.demo_password}"
    identity          = "${element(aws_iam_user.nodejs.*.name, count.index)}"

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
    access_key        = "${element(aws_iam_access_key.nodejs.*.id, count.index)}"
    secret_key        = "${element(aws_iam_access_key.nodejs.*.secret, count.index)}"

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
data "template_cloudinit_config" "nodejs" {
  count = "${var.nodejsservers}"

  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = "${element(data.template_file.nodejs.*.rendered, count.index)}"
  }
}

# IAM
resource "aws_iam_role" "nodejs" {
  count              = "${var.nodejsservers}"
  name               = "${element(aws_iam_user.nodejs.*.name, count.index)}-nodejs"
  assume_role_policy = "${file("${path.module}/templates/policies/assume-role.json")}"
}

resource "aws_iam_policy" "nodejs" {
  count       = "${var.nodejsservers}"
  name        = "${element(aws_iam_user.nodejs.*.name, count.index)}-nodejs"
  description = "Allows user ${element(aws_iam_user.nodejs.*.name, count.index)} to use their nodejs server."
  policy      = "${element(data.template_file.nodejs_iam_policy.*.rendered, count.index)}"
}

resource "aws_iam_policy_attachment" "nodejs" {
  count      = "${var.nodejsservers}"
  name       = "${element(aws_iam_user.nodejs.*.name, count.index)}-nodejs"
  roles      = ["${element(aws_iam_role.nodejs.*.name, count.index)}"]
  policy_arn = "${element(aws_iam_policy.nodejs.*.arn, count.index)}"
}

resource "aws_iam_instance_profile" "nodejs" {
  count = "${var.nodejsservers}"
  name  = "${element(aws_iam_user.nodejs.*.name, count.index)}-nodejs"
  role  = "${element(aws_iam_role.nodejs.*.name, count.index)}"
}

resource "aws_instance" "nodejs" {
  count = "${var.nodejsservers}"

  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.medium"
  key_name      = "${aws_key_pair.consuldemo.id}"

  subnet_id              = "${element(aws_subnet.consuldemo.*.id, count.index)}"
  iam_instance_profile   = "${element(aws_iam_instance_profile.nodejs.*.name, count.index)}"
  vpc_security_group_ids = ["${aws_security_group.consuldemo.id}"]

  tags {
    Name       = "${element(aws_iam_user.nodejs.*.name, count.index)}"
    owner      = "${var.owner}"
    created-by = "${var.created-by}"
  }

  user_data = "${element(data.template_cloudinit_config.nodejs.*.rendered, count.index)}"

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

output "nodejs" {
  value = ["${aws_instance.nodejs.*.public_ip}"]
}

output "nodejs_webterminal_links" {
  value = "${formatlist("http://%s/wetty", aws_instance.nodejs.*.public_ip)}"
}
