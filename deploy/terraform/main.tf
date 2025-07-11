terraform {
  required_providers {
    ovh = {
      source = "ovh/ovh"
    }
  }
  backend "s3" {
    bucket                      = "lucas-backends-terraform"
    key                         = "ovh/state/terraform.tfstate"
    region                      = "sbg" # Random us region not used for ovh backend
    endpoints                   = { s3 = "https://s3.sbg.io.cloud.ovh.net" }
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    use_path_style              = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}

provider "ovh" {
}

##############################################################################
#                                NETWORK                                     #
##############################################################################
resource "ovh_cloud_project_network_private" "network" {
  service_name = "569db610a93e443091a06c6d8827906b" # Public Cloud service name
  name         = "terraform_mks_multiaz_private_net"
  regions      = ["EU-WEST-PAR"]
}

resource "ovh_cloud_project_network_private_subnet" "subnet" {
  service_name = ovh_cloud_project_network_private.network.service_name
  network_id   = ovh_cloud_project_network_private.network.id

  # whatever region, for test purpose
  region     = "EU-WEST-PAR"
  start      = "10.1.0.2"
  end        = "10.1.0.62"
  network    = "10.1.0.0/26"
  dhcp       = true
  no_gateway = false
}

resource "ovh_cloud_project_gateway" "gateway" {
  service_name = ovh_cloud_project_network_private.network.service_name
  name         = "gateway"
  model        = "s"
  region       = "EU-WEST-PAR"
  network_id   = tolist(ovh_cloud_project_network_private.network.regions_attributes[*].openstackid)[0]
  subnet_id    = ovh_cloud_project_network_private_subnet.subnet.id
}


##############################################################################
#                        MANAGED MYSQL DATABASE                              #
##############################################################################
resource "ovh_cloud_project_database" "mysqldb" {
  service_name = "569db610a93e443091a06c6d8827906b"
  description  = "my-first-mysql"
  engine       = "mysql"
  version      = "8"
  plan         = "production"
  nodes {
    region     = "EU-WEST-PAR"
    subnet_id  = ovh_cloud_project_network_private_subnet.subnet.id
    network_id = tolist(ovh_cloud_project_network_private.network.regions_attributes[*].openstackid)[0]
  }
  nodes {
    region     = "EU-WEST-PAR"
    subnet_id  = ovh_cloud_project_network_private_subnet.subnet.id
    network_id = tolist(ovh_cloud_project_network_private.network.regions_attributes[*].openstackid)[0]
  }
  flavor = "b3-8"
  advanced_configuration = {
    "mysql.sql_mode" : "ANSI,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION,NO_ZERO_DATE,NO_ZERO_IN_DATE,STRICT_ALL_TABLES",
    "mysql.sql_require_primary_key" : "true"
  }
  ip_restrictions {
    description = "private network ip"
    ip          = "10.1.0.0/26"
  }
  depends_on = [ovh_cloud_project_network_private_subnet.subnet]
}

resource "ovh_cloud_project_database_user" "user" {
  service_name = "569db610a93e443091a06c6d8827906b"
  engine       = "mysql"
  cluster_id   = ovh_cloud_project_database.mysqldb.id
  name         = "lucas"
}

output "user_password" {
  value     = ovh_cloud_project_database_user.user.password
  sensitive = true
}

##############################################################################
#                        MANAGED KUBERNETES SERVICE                          #
##############################################################################
resource "ovh_cloud_project_kube" "my_multizone_cluster" {
  service_name = ovh_cloud_project_network_private.network.service_name
  name         = "multi-zone-mks"
  region       = "EU-WEST-PAR"

  private_network_id = tolist(ovh_cloud_project_network_private.network.regions_attributes[*].openstackid)[0]
  nodes_subnet_id    = ovh_cloud_project_network_private_subnet.subnet.id

  depends_on = [ovh_cloud_project_database_user.user]
}

resource "time_sleep" "wait_for_cluster" {
  depends_on      = [ovh_cloud_project_kube.my_multizone_cluster]
  create_duration = "60s"
}

resource "ovh_cloud_project_kube_nodepool" "node_pool_multi_zones_a" {
  service_name       = ovh_cloud_project_network_private.network.service_name
  kube_id            = ovh_cloud_project_kube.my_multizone_cluster.id
  name               = "my-pool-zone-a"
  flavor_name        = "b3-8"
  desired_nodes      = 1
  availability_zones = ["eu-west-par-a"]
  depends_on         = [time_sleep.wait_for_cluster]
}

resource "ovh_cloud_project_kube_nodepool" "node_pool_multi_zones_b" {
  service_name       = ovh_cloud_project_network_private.network.service_name
  kube_id            = ovh_cloud_project_kube.my_multizone_cluster.id
  name               = "my-pool-zone-b"
  flavor_name        = "b3-8"
  desired_nodes      = 1
  availability_zones = ["eu-west-par-b"]
  depends_on         = [time_sleep.wait_for_cluster]
}

resource "ovh_cloud_project_kube_nodepool" "node_pool_multi_zones_c" {
  service_name       = ovh_cloud_project_network_private.network.service_name
  kube_id            = ovh_cloud_project_kube.my_multizone_cluster.id
  name               = "my-pool-zone-c"
  flavor_name        = "b3-8"
  desired_nodes      = 1
  availability_zones = ["eu-west-par-c"]
  depends_on         = [time_sleep.wait_for_cluster]
}
