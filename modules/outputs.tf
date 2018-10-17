output "consul_servers" {
  value = ["${aws_instance.server.*.public_ip}"]
}

output "nomad_workers_server" {
  value = ["${aws_instance.workers.*.public_ip}"]
}

output "nomad_workers_consul_ui" {
  value = "${formatlist("http://%s:8500/", aws_instance.workers.*.public_ip,)}"
}

output "nomad_workers_ui" {
  value = "${formatlist("http://%s:3000/", aws_instance.workers.*.public_ip)}"
}

output "fabio_lb" {
  value = "${aws_alb.fabio.dns_name}"
}

output "vault_root_token" {
  value = "${random_id.vault-root-token.hex}"
}

output "vault_lb" {
  value = "${aws_alb.vault.dns_name}"
}

output "vault_ui" {
  value = "http://${aws_alb.vault.dns_name}"
}

output "vpc_id" {
  value = "${aws_vpc.consuldemo.id}"
}

/*
output "zStartscript" {
  value = <<README
  this is a test:
rs.initiate({
   _id : rs0,
  README
}

output "zmembers: " {
  value = "${formatlist("{ host : \"%s:27017\" }",aws_instance.workers.*.private_ip,)}"
}

output "zzendscript" {
  value = <<README
})
  README
}
*/

