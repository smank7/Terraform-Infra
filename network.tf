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

//assign7

resource "google_pubsub_topic" "verify_email" {  
  name="verify_email"
  message_retention_duration = "604800s"
}

resource "google_pubsub_subscription" "verify_email_subscription" {  
  name = "verify_email_subscription"
  topic = google_pubsub_topic.verify_email.name
  ack_deadline_seconds = 20
  push_config {
    push_endpoint = google_cloudfunctions2_function.verify_email_function.url
  }
}

resource "google_vpc_access_connector" "vpc_connector" {  
  name = "new-webapp-vpc-connector" 
  network = google_compute_network.vpc.self_link
  region = var.region
  ip_cidr_range = "10.2.0.0/28"
}

resource "google_storage_bucket" "serverless-bucket" { 
  name= "saaaaa1"
  location = "US"
}

resource "google_storage_bucket_object" "serverless-archive" {
  name = "serverless.zip"
  bucket = google_storage_bucket.serverless-bucket.name
  source = "./serverless.zip"
}

resource "google_cloudfunctions2_function" "verify_email_function" { 
  depends_on = [ google_vpc_access_connector.vpc_connector ]
  name="verify-email-function"
  description = "Verification of Email"
  location = "us-east4"

  build_config {
    runtime = "nodejs20"
    entry_point = "sendVerificationEmail"
    source {
      storage_source {
        bucket = google_storage_bucket.serverless-bucket.name
        object = google_storage_bucket_object.serverless-archive.name
      }
    }
  }

  service_config {
    max_instance_count = 3
    min_instance_count = 2
    available_memory = "256Mi"
    available_cpu = 1
    timeout_seconds = 540
    max_instance_request_concurrency = 1
    environment_variables = {
      DB_HOST= google_sql_database_instance.cloudsql_instance.private_ip_address
      DB_USER= "webapp"
      DB_PASS= random_password.password.result
      DB_NAME="webapp"
      DB_PORT=3306

    }
    ingress_settings =  "ALLOW_INTERNAL_ONLY"
    all_traffic_on_latest_revision = true
    vpc_connector = google_vpc_access_connector.vpc_connector.name
    vpc_connector_egress_settings = "PRIVATE_RANGES_ONLY"
  }
  event_trigger {
    trigger_region = "us-east4"
    event_type = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic = google_pubsub_topic.verify_email.id
    service_account_email = google_service_account.service_account.email
    retry_policy = "RETRY_POLICY_RETRY"
  }
  
}

resource "google_project_iam_binding" "cloud_run_invoker" {  
  project = var.project_id
  role="roles/run.invoker"
  members = ["serviceAccount:${google_service_account.service_account.email}"]
  
}

resource "google_project_iam_binding" "pubsub_publisher" {     
  project = var.project_id
  role = "roles/pubsub.publisher"
  members = ["serviceAccount:${google_service_account.service_account.email}"]
}

//assign8

resource "google_compute_region_instance_template" "web_instance_template" {
  name                    = "web-instance-template"
  machine_type            = "e2-medium"
  region                  = var.region
  tags         = ["webapp-lb-target", "ssh-access","application-instance"]
  
  disk {
    source_image = var.vm_image
     auto_delete  = true
     boot         = true
  }

  service_account {
    email  = google_service_account.service_account.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
     }

  network_interface {
    network = google_compute_network.vpc.self_link
    subnetwork = google_compute_subnetwork.webapp_subnet.self_link
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
}

resource "google_compute_region_instance_group_manager" "igm" {
  name              = "my-igm-new-cloud"
  region = var.region
  //zone = var.zone
  base_instance_name = "web-instance"


  version {
    instance_template = google_compute_region_instance_template.web_instance_template.id
    name = "primary"
  }
 
  target_size = 1

  named_port {

    name = "http"

    //This name given to the 'named_port' in the MIG must match the 'port_name' in the 'google_compute_backend_service'

    port = "3000"

  }
   update_policy {



    type = "PROACTIVE"

    //MIG 'proactively' executes actions in order to bring instances to their target template version



    instance_redistribution_type = "PROACTIVE"

    //MIG attempts to maintain an even distribution of VM instances across all the zones in the region



    minimal_action = "REPLACE"


    most_disruptive_allowed_action = "REPLACE"
    max_surge_fixed = 3

  }
   auto_healing_policies {

    health_check      = google_compute_health_check.web_health_check.self_link

    initial_delay_sec = 300

  }

}



resource "google_compute_region_autoscaler" "web_autoscaler" {
  project = var.project_id
  name   = "web-autoscaler"
  region = var.region
  target = google_compute_region_instance_group_manager.igm.id

  autoscaling_policy {
    min_replicas = 1
    max_replicas = 3
    
    cpu_utilization {
      target = 0.05
    }
  }

  depends_on = [google_compute_region_instance_group_manager.igm]
}


resource "google_compute_firewall" "lb_firewall" {
  name    = "lb-firewall"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]  # Adjust as necessary, should be load balancer IP range
  target_tags   = ["webapp-lb-target","application-instance"]
}

resource "google_compute_global_address" "lb_ip" {
  name          = "lb-ip"
  ip_version    = "IPV4"
  
}

resource "google_compute_managed_ssl_certificate" "lb_default" {
  project     = var.project_id 
  name     = "cloudcsye-ssl-cert"

  managed {
    domains = ["santoshicloud.me"]
  }
}

# Define the HTTPS health check for your backend service
resource "google_compute_health_check" "web_health_check" {
  name               = "web-health-check"
  check_interval_sec = 10
  timeout_sec        = 5

  http_health_check {
    request_path = "/healthz"
    port = 3000
  }
}

# Define the backend service
resource "google_compute_backend_service" "backend_service" {
  name             = "backend-service"
  protocol         = "HTTP"
  port_name        = "http"
  timeout_sec      = 10
  enable_cdn       = false
  health_checks    = [google_compute_health_check.web_health_check.id]

 backend {
    group = google_compute_region_instance_group_manager.igm.instance_group
  }
}

# Define the URL map
resource "google_compute_url_map" "url_map" {
  name            = "url-maps"
  default_service = google_compute_backend_service.backend_service.self_link
}

# Define the target HTTPS proxy
resource "google_compute_target_https_proxy" "lb_https_proxy" {
  name             = "lb-https-proxy"
  url_map          = google_compute_url_map.url_map.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.lb_default.self_link]
}

# Define the global forwarding rule
resource "google_compute_global_forwarding_rule" "lb_forwarding_rule" {
  name       = "lb-forwarding-rule"
  ip_protocol = "TCP"
  port_range = 443
  target     = google_compute_target_https_proxy.lb_https_proxy.self_link
  ip_address    = google_compute_global_address.lb_ip.address

  // add ip addresses
}

resource "google_project_iam_member" "lb_admin" {
  project = var.project_id
  role    = "roles/compute.loadBalancerAdmin"
  member = "serviceAccount:${google_service_account.service_account.email}"
}


resource "google_project_iam_member" "dns_admin" {
  project = var.project_id
  role    = "roles/dns.admin"
  member = "serviceAccount:${google_service_account.service_account.email}"
  
}


resource "google_dns_record_set" "my_dns_record" {
  name    = data.google_dns_managed_zone.my_dns_zone.dns_name
  type    = "A"
  ttl     = 300
  managed_zone =  data.google_dns_managed_zone.my_dns_zone.name
  
  rrdatas = [
   google_compute_global_address.lb_ip.address
  ]
}

data "google_iam_policy" "admin" {
  binding {
    role = "roles/viewer"

    members = [
      "serviceAccount:${google_service_account.service_account.email}",
    ]
  }
}






