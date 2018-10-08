// Primary
output "primary_consul_servers" {
 value = "${module.primarycluster.consul_servers}"
}

output "primary_vault_ui" {
   value = "${module.primarycluster.vault_ui}"
}

output "primary_angularjs_consul_ui" {
   value = "${module.primarycluster.angularjs_consul_ui}"
}

output "primary_vpc_id" {
   value = "${module.primarycluster.vpc_id}"
}

/*
output "angularjs_server" {
  value = "${module.primarycluster.angularjs_server}"
}

output "angularjs_consul_ui" {
   value = "${module.primarycluster.angularjs_consul_ui}"
}

output "angularjs_web_server" {
  value = "${module.primarycluster.angularjs_web_server}"
}


output "fabio_lb" {
  value = "${module.primarycluster.fabio_lb}"
}

output "mongodb_server" {
  value = "${module.primarycluster.mongodb_server}"
}

output "mongodb_consul_ui" {
  value = "${module.primarycluster.mongodb_consul_ui}"
}


output "nodejs_server" {
  value = "${module.primarycluster.nodejs_server}"
}

output "nodejs_api_rfi" {
   value = "${module.primarycluster.nodejs_api_rfi}"
}

output "nodejs_consul_ui" {
  value = "${module.primarycluster.nodejs_consul_ui}"
}


output "vault_lb" {
  value = "${module.primarycluster.vault_lb}"
}

output "vault_ui" {
   value = "${module.primarycluster.vault_ui}"
}
*/

// Secondary
output "secondary_consul_servers" {
 value = "${module.secondarycluster.consul_servers}"
}

output "secondary_vault_ui" {
   value = "${module.secondarycluster.vault_ui}"
}

output "secondary_angularjs_consul_ui" {
   value = "${module.secondarycluster.angularjs_consul_ui}"
}


output "secondary_vpc_id" {
   value = "${module.secondarycluster.vpc_id}"
}