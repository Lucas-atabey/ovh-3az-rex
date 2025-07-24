output "component" {
  value = ovh_cloud_project_database.mysqldb.endpoints[0].component
}

output "domain" {
  value = ovh_cloud_project_database.mysqldb.endpoints[0].domain
}

output "path" {
  value = ovh_cloud_project_database.mysqldb.endpoints[0].path
}

output "port" {
  value = ovh_cloud_project_database.mysqldb.endpoints[0].port
}

output "scheme" {
  value = ovh_cloud_project_database.mysqldb.endpoints[0].scheme
}

output "ssl" {
  value = ovh_cloud_project_database.mysqldb.endpoints[0].ssl
}

output "ssl_mode" {
  value = ovh_cloud_project_database.mysqldb.endpoints[0].ssl_mode
}

output "uri" {
  value = ovh_cloud_project_database.mysqldb.endpoints[0].uri
}

output "user_password" {
  value     = ovh_cloud_project_database_user.user.password
  sensitive = true
}

output "instance_a_floating_ip" {
  value = [
    for addr in ovh_cloud_project_instance.instance_a.addresses :
    addr.ip if !(startswith(addr.ip, "10.") || startswith(addr.ip, "192.168.") || startswith(addr.ip, "172.16."))
  ][0]
}

output "instance_b_floating_ip" {
  value = [
    for addr in ovh_cloud_project_instance.instance_b.addresses :
    addr.ip if !(startswith(addr.ip, "10.") || startswith(addr.ip, "192.168.") || startswith(addr.ip, "172.16."))
  ][0]
}

output "instance_c_floating_ip" {
  value = [
    for addr in ovh_cloud_project_instance.instance_c.addresses :
    addr.ip if !(startswith(addr.ip, "10.") || startswith(addr.ip, "192.168.") || startswith(addr.ip, "172.16."))
  ][0]
}
