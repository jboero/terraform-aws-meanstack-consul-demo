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
