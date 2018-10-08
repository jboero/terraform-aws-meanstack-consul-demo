data "template_file" "server" {
  count = "${var.servers}"

  template = "${join("\n", list(
    file("${path.module}/templates/shared/base.sh"),
    file("${path.module}/templates/shared/docker.sh"),

    file("${path.module}/templates/server/consul.sh"),
    file("${path.module}/templates/server/vault.sh"),
    file("${path.module}/templates/server/nomad.sh"),
    file("${path.module}/templates/server/nomad-jobs.sh"),

    file("${path.module}/templates/shared/cleanup.sh"),
  ))}"

  vars {
    awsaccesskey = "${var.awsaccesskey}"
    awssecretkey = "${var.awssecretkey}"
    region       = "${var.region}"
    enterprise   = "${var.enterprise}"
    vaultlicense = "${var.vaultlicense}"
    consullicense = "${var.consullicense}"
    kmskey       = "${aws_kms_key.consulDemoVaultKeys.id}"
    namespace    = "${var.namespace}"
    node_name    = "${var.namespace}-server-${count.index}"
    me_ca        = "${tls_self_signed_cert.root.cert_pem}"
    me_cert      = "${element(tls_locally_signed_cert.server.*.cert_pem, count.index)}"
    me_key       = "${element(tls_private_key.server.*.private_key_pem, count.index)}"

    # Consul
    consul_url            = "${var.consul_url}"
    consul_ent_url            = "${var.consul_ent_url}"
    consul_gossip_key     = "${base64encode(random_id.consul_gossip_key.hex)}"
    consul_join_tag_key   = "ConsulJoin"
    consul_join_tag_value = "${local.consul_join_tag_value}"
    consul_master_token   = "${random_id.consul_master_token.hex}"
    consul_servers        = "${var.servers}"

    # Nomad
    nomad_url        = "${var.nomad_url}"
    nomad_gossip_key = "${base64encode(random_id.nomad_gossip_key.hex)}"
    nomad_servers    = "${var.servers}"

    # Nomad jobs
    fabio_url   = "${var.fabio_url}"
    hashiui_url = "${var.hashiui_url}"

    # Vault
    vault_url        = "${var.vault_url}"
    vault_ent_url    = "${var.vault_ent_url}"
    vault_root_token = "${random_id.vault-root-token.hex}"
    vault_servers    = "${var.servers}"
  }
}

# Gzip cloud-init config
data "template_cloudinit_config" "server" {
  count = "${var.servers}"

  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = "${element(data.template_file.server.*.rendered, count.index)}"
  }
}

# Create the Consul cluster
resource "aws_instance" "server" {
  count = "${var.servers}"

  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "r4.large"
  key_name      = "${aws_key_pair.consuldemo.id}"

  subnet_id              = "${element(aws_subnet.consuldemo.*.id, count.index)}"
  iam_instance_profile   = "${aws_iam_instance_profile.consul-join.name}"
  vpc_security_group_ids = ["${aws_security_group.consuldemo.id}"]

  tags {
    Name           = "${var.namespace}-server-${count.index}"
    owner          = "${var.owner}"
    created-by     = "${var.created-by}"
    sleep-at-night = "${var.sleep-at-night}"
    TTL            = "${var.TTL}"
    ConsulJoin     = "${local.consul_join_tag_value}"
  }

  user_data = "${element(data.template_cloudinit_config.server.*.rendered, count.index)}"
}

