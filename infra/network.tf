#Deploying Management network
resource "google_compute_network" "mgmt" {
  name = var.mgmt-net
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "f5-mgmt-sub" {
  name          = "mgmt"
  ip_cidr_range = var.mgmt_cidr
  region        = var.region
  network       = google_compute_network.mgmt.id
}

resource "google_compute_firewall" "mgmt-firewall" {
  name        = "mgmt"
  network     = google_compute_network.mgmt.id

  allow {
    protocol  = "tcp"
    ports     = ["22", "443"]
  }
  target_tags = ["f5-lb"]
  source_ranges = ["0.0.0.0/0"]
}


#Deploying App network
resource "google_compute_network" "app" {
  name = var.app-net
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "f5-sub" {
  name          = "f5-lb"
  ip_cidr_range = var.app_cidr
  region        = var.region
  network       = google_compute_network.app.id
}

resource "google_compute_subnetwork" "control-sub" {
  name          = "control-plane"
  ip_cidr_range = var.control_cidr
  region        = var.region
  network       = google_compute_network.app.id
}

resource "google_compute_subnetwork" "etcd" {
  name          = "etcd"
  ip_cidr_range = var.etcd_cidr
  region        = var.region
  network       = google_compute_network.app.id
}

resource "google_compute_subnetwork" "nodes" {
  name          = "nodes"
  ip_cidr_range = var.nodes_cidr
  region        = var.region
  network       = google_compute_network.app.id
}

resource "google_compute_firewall" "etcd-internal" {
  name        = "etcd-internal"
  network     = google_compute_network.app.id

  allow {
    protocol  = "tcp"
    ports     = ["2379", "2380", "2381"]
  }
  target_tags = ["etcd"]
  source_tags = ["etcd"]
}

resource "google_compute_firewall" "control-internal" {
  name        = "control-internal"
  network     = google_compute_network.app.id

  allow {
    protocol  = "tcp"
    ports     = ["6443", "10250", "10257", "10259"]
  }
  target_tags = ["control"]
  source_tags = ["control"]
}

resource "google_compute_firewall" "f5-etcd" {
  name        = "f5-etcd"
  network     = google_compute_network.app.id

  allow {
    protocol  = "tcp"
    ports     = ["2379", "2381"]
  }
  target_tags = ["etcd"]
  source_tags = ["f5-lb"]
}

resource "google_compute_firewall" "f5-control-plane" {
  name        = "f5-control-plane"
  network     = google_compute_network.app.id

  allow {
    protocol  = "tcp"
    ports     = ["6443"]
  }
  target_tags = ["control"]
  source_tags = ["f5-lb"]
}

resource "google_compute_firewall" "control-plane-f5" {
  name        = "control-plane-f5"
  network     = google_compute_network.app.id

  allow {
    protocol  = "tcp"
    ports     = ["6443"]
  }
  target_tags = ["f5-lb"]
  source_tags = ["control"]
}

resource "google_compute_firewall" "control-etcd" {
  name        = "control-etcd"
  network     = google_compute_network.app.id

  allow {
    protocol  = "tcp"
    ports     = ["2379"]
  }
  target_tags = ["f5-lb"]
  source_tags = ["control"]
}

#Temporary rule for config
resource "google_compute_firewall" "default" {
  name        = "default"
  network     = google_compute_network.app.id

  allow {
    protocol  = "tcp"
    ports     = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}

#DNS Configuration

resource "google_dns_managed_zone" "rvloona-internal" {
  name        = "rvloona-internal"
  dns_name    = "rvloona.com."

  visibility = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.app.id
    }
  }
}

resource "google_dns_record_set" "etcd" {
  managed_zone = google_dns_managed_zone.rvloona-internal.name
  name         = "etcd.internal.rvloona.com."
  type         = "A"
  rrdatas      = [var.app_static]
  ttl          = 300
}

resource "google_dns_record_set" "control-plane" {
  managed_zone = google_dns_managed_zone.rvloona-internal.name
  name         = "plane.internal.rvloona.com."
  type         = "A"
  rrdatas      = [var.app_static]
  ttl          = 300
}

#Deploying static IPs for F5
resource "google_compute_address" "f5-mgmt-static-internal" {
  name          = "f5-mgmt"
  address_type = "INTERNAL"
  subnetwork   = google_compute_subnetwork.f5-mgmt-sub.id
  address      = var.mgmt_static
  region       = var.region
}

resource "google_compute_address" "f5-mgmt-static-external" {
  name          = "f5-mgmt-external"
  address_type = "EXTERNAL"
  region = var.region
}

resource "google_compute_address" "f5-app-static-internal" {
  name          = "f5-app"
  address_type = "INTERNAL"
  subnetwork   = google_compute_subnetwork.f5-sub.id
  address      = var.app_static
  region       = var.region
}

resource "google_compute_address" "f5-app-static-external" {
  name          = "f5-app-external"
  address_type = "EXTERNAL"
  region = var.region
}