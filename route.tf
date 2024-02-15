resource "google_compute_route" "webapp_route_to_internet" {
  name             = "${var.vpc_name}-webapp-route"
  dest_range       = "0.0.0.0/0"
  network          = google_compute_network.vpc.id
  next_hop_gateway = "default-internet-gateway"
  depends_on = [
    google_compute_subnetwork.webapp_subnet,
  ]  
}