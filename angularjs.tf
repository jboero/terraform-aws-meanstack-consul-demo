resource "aws_iam_user" "angularjs" {
  count = "${var.angularjsservers}"

  name = "${var.namespace}-angularjs-${count.index}"
  path = "/${var.namespace}/"
}

resource "aws_iam_access_key" "angularjs" {
  count = "${var.angularjsservers}"
  user  = "${element(aws_iam_user.angularjs.*.name, count.index)}"
}

data "template_file" "angularjs_iam_policy" {
  count    = "${var.angularjsservers}"
  template = "${file("${path.module}/templates/policies/iam_policy.json.tpl")}"

  vars {
    identity          = "${element(aws_iam_user.angularjs.*.name, count.index)}"
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
resource "aws_iam_user_policy" "angularjs" {
  count  = "${var.angularjsservers}"
  name   = "policy-${element(aws_iam_user.angularjs.*.name, count.index)}"
  user   = "${element(aws_iam_user.angularjs.*.name, count.index)}"
  policy = "${element(data.template_file.angularjs_iam_policy.*.rendered, count.index)}"
}

data "template_file" "angularjs" {
  count = "${var.angularjsservers}"

  template = "${join("\n", list(
    file("${path.module}/templates/shared/base.sh"),
    file("${path.module}/templates/shared/docker.sh"),

    file("${path.module}/templates/angularjs/user.sh"),
    file("${path.module}/templates/angularjs/consul.sh"),
    file("${path.module}/templates/angularjs/vault.sh"),
    file("${path.module}/templates/angularjs/postgres.sh"),
    file("${path.module}/templates/angularjs/terraform.sh"),
    file("${path.module}/templates/angularjs/tools.sh"),
    file("${path.module}/templates/angularjs/nomad.sh"),
    file("${path.module}/templates/angularjs/webterminal.sh"),
    file("${path.module}/templates/angularjs/connectdemo.sh"),
    file("${path.module}/templates/shared/cleanup.sh"),
  ))}"

  vars {
    namespace = "${var.namespace}"
    node_name = "${element(aws_iam_user.angularjs.*.name, count.index)}"
    me_ca     = "${tls_self_signed_cert.root.cert_pem}"
    me_cert   = "${element(tls_locally_signed_cert.angularjs.*.cert_pem, count.index)}"
    me_key    = "${element(tls_private_key.angularjs.*.private_key_pem, count.index)}"

    # User
    demo_username = "${var.demo_username}"
    demo_password = "${var.demo_password}"
    identity      = "${element(aws_iam_user.angularjs.*.name, count.index)}"

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
    access_key        = "${element(aws_iam_access_key.angularjs.*.id, count.index)}"
    secret_key        = "${element(aws_iam_access_key.angularjs.*.secret, count.index)}"

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
data "template_cloudinit_config" "angularjs" {
  count = "${var.angularjsservers}"

  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = "${element(data.template_file.angularjs.*.rendered, count.index)}"
  }
}

# IAM
resource "aws_iam_role" "angularjs" {
  count              = "${var.angularjsservers}"
  name               = "${var.namespace}-angularjs-${count.index}"
  assume_role_policy = "${file("${path.module}/templates/policies/assume-role.json")}"
}

resource "aws_iam_policy" "angularjs" {
  count       = "${var.angularjsservers}"
  name        = "${var.namespace}-angularjs-${count.index}"
  description = "Allows user ${element(aws_iam_user.angularjs.*.name, count.index)} to use their angularjs server."
  policy      = "${element(data.template_file.angularjs_iam_policy.*.rendered, count.index)}"
}

resource "aws_iam_policy_attachment" "angularjs" {
  count      = "${var.angularjsservers}"
  name       = "${var.namespace}-angularjs-${count.index}"
  roles      = ["${element(aws_iam_role.angularjs.*.name, count.index)}"]
  policy_arn = "${element(aws_iam_policy.angularjs.*.arn, count.index)}"
}

resource "aws_iam_instance_profile" "angularjs" {
  count = "${var.angularjsservers}"
  name  = "${var.namespace}-angularjs-${count.index}"
  role  = "${element(aws_iam_role.angularjs.*.name, count.index)}"
}

resource "aws_instance" "angularjs" {
  count = "${var.angularjsservers}"

  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.medium"
  key_name      = "${aws_key_pair.consuldemo.id}"

  subnet_id              = "${element(aws_subnet.consuldemo.*.id, count.index)}"
  iam_instance_profile   = "${element(aws_iam_instance_profile.angularjs.*.name, count.index)}"
  vpc_security_group_ids = ["${aws_security_group.consuldemo.id}"]

  tags {
    Name       = "${var.namespace}-angularjs-${count.index}"
    owner      = "${var.owner}"
    created-by = "${var.created-by}"
  }

  user_data = "${element(data.template_cloudinit_config.angularjs.*.rendered, count.index)}"

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

output "angularjs server" {
  value = ["${aws_instance.angularjs.*.public_ip}"]
}

output "angularjs_consul ui" {
  value = "${formatlist("http://%s:8500/", aws_instance.angularjs.*.public_ip)}"
}

output "angularjs_web_server" {
  value = "${formatlist("http://%s:3000/", aws_instance.angularjs.*.public_ip)}"
}
