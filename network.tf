resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  delete_default_routes_on_create = true  
}

resource "google_compute_subnetwork" "db_subnet" {
  name          = "db"
  ip_cidr_range = var.db_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
}
resource "google_compute_subnetwork" "webapp_subnet" {
  name          = "webapp"
  ip_cidr_range = var.webapp_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
}



resource "google_compute_route" "webapp_route" {
  name             = "${var.vpc_name}-webapp-route"
  dest_range       = "0.0.0.0/0"
  network          = google_compute_network.vpc.id
  next_hop_gateway = "default-internet-gateway"
  priority         = 1000

  depends_on = [
    google_compute_subnetwork.webapp_subnet,
  ]
}

resource "google_compute_firewall" "deny_ssh" {
  name    = "${var.vpc_name}-deny-ssh"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_webapplication" {
  name    = "${var.vpc_name}-allow-webapplication"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = [var.app_port]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "db_allow_firewall" {
  name    = "${var.vpc_name}-allow-db"
  network = google_compute_network.vpc.id
  allow {
    protocol = "tcp"
    ports    = [var.db_port]
  }
  target_tags   = []
  source_ranges = [google_compute_subnetwork.webapp_subnet.ip_cidr_range]
}

resource "google_compute_global_address" "private_ip_address" {
  # count         = length(var.vpcs)
   name          =  var.private_ip_name
  purpose       = var.private_ip_purpose
  address_type  = var.private_ip_address_type
  prefix_length = 16
  network       = google_compute_network.vpc.id
}
 
resource "google_service_networking_connection" "private_vpc_connection" {
  # count                   = length(var.vpcs)
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
  deletion_policy = "ABANDON"
}



resource "google_sql_database_instance" "cloudsql_instance" {
  name             = var.instance_name
  database_version = var.mysql_version
  region           = var.region
  depends_on          = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier              = var.db_tier
    availability_type = "REGIONAL"
    disk_type         = var.sql_disk_type
    disk_size         = var.sql_disk_size_gb
    disk_autoresize   = true

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.self_link
      enable_private_path_for_google_cloud_services = true
    }

  
    backup_configuration {
      enabled            = true
      binary_log_enabled = true
    }
  }

  deletion_protection = false
}


resource "google_sql_database" "webapp_database" {
  name     = var.db_name
  instance = google_sql_database_instance.cloudsql_instance.name
}

resource "google_sql_user" "webapp_user" {
  name     = var.db_user
  instance = google_sql_database_instance.cloudsql_instance.name
  host     = var.host
  password = random_password.password.result
}

resource "random_password" "password" {
  length  = var.password_length
  special = false

}

resource "google_compute_instance" "vm_instance" {
  name         = var.vm_name  
  zone         = var.vm_zone
  machine_type = var.vm_machine_type

  boot_disk {
    initialize_params {
      image = var.vm_image
      type  = var.vm_disk_type
      size  = var.vm_disk_size_gb
    }
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.webapp_subnet.id

    access_config {
    }
  }
metadata = {
  startup-script = <<-SCRIPT
      #!/bin/bash


      # Write to dotenv file
      sudo cat <<EOF > /opt/.env
      DB_HOST=${google_sql_database_instance.cloudsql_instance.private_ip_address}
      DB_DATABASE=${google_sql_database.webapp_database.name}
      DB_USER=${google_sql_user.webapp_user.name}
      DB_PASSWORD=${random_password.password.result}
      DB_PORT=${var.db_port}
      EOF

      # Print the contents of the .env file for debugging
      sudo cat /opt/.env

      # Change ownership of the file
      sudo chown csye6225:csye6225 /opt/.env
  SCRIPT
}

# depends_on = [
#   google_sql_database_instance.cloudsql_instance,
#   google_sql_database.webapp_database,
#   google_sql_user.webapp_user,
#   random_password.password,
# ]
service_account{
    email= google_service_account.service_account.email
    scopes= ["cloud-platform"]
  }
}


//assignment 6
data "google_dns_managed_zone" "my_dns_zone" {
  name        = "santoshi"
}

# Define the DNS record for your VM instance
resource "google_dns_record_set" "my_dns_record" {
  name    = data.google_dns_managed_zone.my_dns_zone.dns_name
  type    = "A"
  ttl     = 300
  managed_zone =  data.google_dns_managed_zone.my_dns_zone.name
  rrdatas = [google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip]
}

resource "google_service_account" "service_account" {
  account_id   = var.serviceaccountid
  display_name = var.serviceaccountname
}

resource "google_project_iam_binding" "logging_admin" {
  project = var.project_id
  role    = "roles/logging.admin"

  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]
}

resource "google_project_iam_binding" "monitoring_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"

  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]
}





