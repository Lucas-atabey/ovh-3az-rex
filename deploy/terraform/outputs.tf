output "kubeconfig_file_eu_west_par" {
  value     = ovh_cloud_project_kube.my_multizone_cluster.kubeconfig
  sensitive = true
}

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
