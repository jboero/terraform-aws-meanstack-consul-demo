provider "aws" {
  version = ">= 1.20.0"
  region  = "${var.region}"
}

module "primarycluster" {
  source           = "./modules"
  owner            = "${var.owner}"
  region           = "${var.region}"
  namespace        = "${var.primarynamespace}"
  public_key       = "${var.public_key}"
  demo_username    = "${var.demo_username}"
  demo_password    = "${var.demo_password}"
  servers          = "${var.servers}"
  nomadworkers     = "${var.nomadworkers}"
  vaultlicense     = "${var.vaultlicense}"
  consullicense    = "${var.consullicense}"
  enterprise       = "${var.enterprise}"
  awsaccesskey     = "${var.awsaccesskey}"
  awssecretkey     = "${var.awssecretkey}"

  # vaultdrinstancetype = "primary"
  vpc_cidr_block = "10.1.0.0/16"
  cidr_blocks    = ["10.1.1.0/24", "10.1.2.0/24"]
}

/*
module "secondarycluster"{
 source = "./modules"
owner = "${var.owner}"
region = "${var.region}"
namespace = "${var.secondarynamespace}"
public_key = "${var.public_key}"
demo_username = "${var.demo_username}"
demo_password = "${var.demo_password}"
nomadworkers = "${var.nomadworkers}"
vaultlicense = "${var.vaultlicense}"
consullicense = "${var.consullicense}"
enterprise = "${var.enterprise}"
awsaccesskey = "${var.awsaccesskey}"
awssecretkey = "${var.awssecretkey}"
#vaultdrinstancetype = "secondary"
vpc_cidr_block = "10.2.0.0/16"
cidr_blocks = ["10.2.1.0/24", "10.2.2.0/24"]
}

resource "aws_vpc_peering_connection" "vaultpeer" {
  peer_vpc_id   = "${module.secondarycluster.vpc_id}"
  vpc_id        = "${module.primarycluster.vpc_id}"
  auto_accept   = true

  tags {
    Name           = "${var.primarynamespace}"
    owner          = "${var.owner}"
    created-by     = "${var.created-by}"
    sleep-at-night = "${var.sleep-at-night}"
    TTL            = "${var.TTL}"
  }
}
*/

