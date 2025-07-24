terraform {
  required_providers {
    ovh = {
      source = "ovh/ovh"
    }
  }
  backend "s3" {
    bucket                      = "lucas-backends-terraform"
    key                         = "ovh/docker_state/terraform.tfstate"
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
  name         = "terraform_instances_multiaz_private_net"
  regions      = ["EU-WEST-PAR"]
}

resource "ovh_cloud_project_network_private_subnet" "subnet" {
  service_name = ovh_cloud_project_network_private.network.service_name
  network_id   = ovh_cloud_project_network_private.network.id

  # whatever region, for test purpose
  region     = "EU-WEST-PAR"
  start      = "10.1.0.2"
  end        = "10.1.0.30"
  network    = "10.1.0.0/27"
  dhcp       = true
  no_gateway = false
  depends_on = [ovh_cloud_project_network_private.network]
}

resource "ovh_cloud_project_gateway" "gateway" {
  service_name = ovh_cloud_project_network_private.network.service_name
  name         = "gateway"
  model        = "s"
  region       = "EU-WEST-PAR"
  network_id   = tolist(ovh_cloud_project_network_private.network.regions_attributes[*].openstackid)[0]
  subnet_id    = ovh_cloud_project_network_private_subnet.subnet.id
  depends_on   = [ovh_cloud_project_network_private_subnet.subnet]
}

resource "time_sleep" "wait_for_gateway" {
  depends_on      = [ovh_cloud_project_gateway.gateway]
  create_duration = "60s"
}

##############################################################################
#                           Docker Instances                                 #
##############################################################################
resource "ovh_cloud_project_ssh_key" "key" {
  service_name = "569db610a93e443091a06c6d8827906b"
  public_key   = var.ssh_public_key
  name         = "lucas"
}

data "ovh_cloud_project_floatingips" "ips" {
  service_name = "569db610a93e443091a06c6d8827906b"
  region_name  = "EU-WEST-PAR"
}

resource "ovh_cloud_project_instance" "instance_a" {
  service_name   = "569db610a93e443091a06c6d8827906b"
  region         = "EU-WEST-PAR"
  billing_period = "hourly"
  boot_from {
    image_id = "2d6a7f34-92d9-47b4-88bb-82f6e63e4870"
  }
  flavor {
    flavor_id = "91fa3187-0f7d-489e-a75e-a7f6541482ee"
  }
  name              = "b3-8-eu-west-par-a"
  availability_zone = "eu-west-par-a"
  network {
    private {
      network {
        id        = tolist(ovh_cloud_project_network_private.network.regions_attributes[*].openstackid)[0]
        subnet_id = ovh_cloud_project_network_private_subnet.subnet.id
      }
      gateway {
        id = ovh_cloud_project_gateway.gateway.id
      }
      floating_ip {
        id = tolist(data.ovh_cloud_project_floatingips.ips.cloud_project_floatingips)[0].id
      }
    }
  }
  ssh_key {
    name = "lucas"
  }
  user_data = templatefile("${path.module}/scripts/cloud-init.yaml", {
    ssh_public_key = var.ssh_public_key
  })
  depends_on = [time_sleep.wait_for_gateway, ovh_cloud_project_ssh_key.key]
}

resource "ovh_cloud_project_instance" "instance_b" {
  service_name   = "569db610a93e443091a06c6d8827906b"
  region         = "EU-WEST-PAR"
  billing_period = "hourly"
  boot_from {
    image_id = "2d6a7f34-92d9-47b4-88bb-82f6e63e4870"
  }
  flavor {
    flavor_id = "91fa3187-0f7d-489e-a75e-a7f6541482ee"
  }
  name              = "b3-8-eu-west-par-b"
  availability_zone = "eu-west-par-b"
  network {
    private {
      network {
        id        = tolist(ovh_cloud_project_network_private.network.regions_attributes[*].openstackid)[0]
        subnet_id = ovh_cloud_project_network_private_subnet.subnet.id
      }
      gateway {
        id = ovh_cloud_project_gateway.gateway.id
      }
      floating_ip {
        id = tolist(data.ovh_cloud_project_floatingips.ips.cloud_project_floatingips)[1].id
      }
    }
  }
  ssh_key {
    name = "lucas"
  }
  user_data = templatefile("${path.module}/scripts/cloud-init.yaml", {
    ssh_public_key = var.ssh_public_key
  })
  depends_on = [time_sleep.wait_for_gateway, ovh_cloud_project_ssh_key.key]
}

resource "ovh_cloud_project_instance" "instance_c" {
  service_name   = "569db610a93e443091a06c6d8827906b"
  region         = "EU-WEST-PAR"
  billing_period = "hourly"
  boot_from {
    image_id = "2d6a7f34-92d9-47b4-88bb-82f6e63e4870"
  }
  flavor {
    flavor_id = "91fa3187-0f7d-489e-a75e-a7f6541482ee"
  }
  name              = "b3-8-eu-west-par-c"
  availability_zone = "eu-west-par-c"
  network {
    private {
      network {
        id        = tolist(ovh_cloud_project_network_private.network.regions_attributes[*].openstackid)[0]
        subnet_id = ovh_cloud_project_network_private_subnet.subnet.id
      }
      gateway {
        id = ovh_cloud_project_gateway.gateway.id
      }
      floating_ip {
        id = tolist(data.ovh_cloud_project_floatingips.ips.cloud_project_floatingips)[2].id
      }
    }
  }
  ssh_key {
    name = "lucas"
  }
  user_data = templatefile("${path.module}/scripts/cloud-init.yaml", {
    ssh_public_key = var.ssh_public_key
  })
  depends_on = [time_sleep.wait_for_gateway, ovh_cloud_project_ssh_key.key]
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
    ip          = "10.1.0.0/27"
  }

  lifecycle {
    ignore_changes = [
      advanced_configuration["mysql.log_output"],
      advanced_configuration["mysql.long_query_time"],
      advanced_configuration["mysql.slow_query_log"],
    ]
  }
  depends_on = [ovh_cloud_project_network_private_subnet.subnet]
}

resource "ovh_cloud_project_database_user" "user" {
  service_name = "569db610a93e443091a06c6d8827906b"
  engine       = "mysql"
  cluster_id   = ovh_cloud_project_database.mysqldb.id
  name         = "lucas"
  depends_on   = [ovh_cloud_project_database.mysqldb]
}
