resource "google_compute_subnetwork" "webapp_subnet" {
  name          = "${var.vpc_name}-webapp"
  ip_cidr_range = var.webapp_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
}
 
resource "google_compute_subnetwork" "db_subnet" {
  name          = "${var.vpc_name}-db"
  ip_cidr_range = var.db_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
}