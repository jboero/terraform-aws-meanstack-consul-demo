output "angularjs_server" {
  value = ["${aws_instance.angularjs.*.public_ip}"]
}

output "angularjs_consul_ui" {
  value = "${formatlist("http://%s:8500/", aws_instance.angularjs.*.public_ip)}"
}

output "angularjs_web_server" {
  value = "${formatlist("http://%s:3000/", aws_instance.angularjs.*.public_ip)}"
}


output "fabio_lb" {
  value = "${aws_alb.fabio.dns_name}"
}

output "mongodb_server" {
  value = ["${aws_instance.mongodb.*.public_ip}"]
}

output "mongodb_consul_ui" {
  value = "${formatlist("http://%s:8500/", aws_instance.mongodb.*.public_ip,)}"
}


output "nodejs_server" {
  value = ["${aws_instance.nodejs.*.public_ip}"]
}

output "nodejs_api_rfi" {
  value = "${formatlist("http://%s:5000/api/rfi", aws_instance.nodejs.*.public_ip)}"
}

output "nodejs_consul_ui" {
  value = "${formatlist("http://%s:8500", aws_instance.nodejs.*.public_ip)}"
}


output "consul_servers" {
  value = ["${aws_instance.server.*.public_ip}"]
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


output "zStartscript" {
  value = <<README
  this is a test:
rs.initiate({
   _id : rs0,
  README
}

output "zmembers: " {
  value = "${formatlist("{ host : \"%s:27017\" }",aws_instance.mongodb.*.private_ip,)}"
}

output "zzendscript" {
  value = <<README
})
  README
}
