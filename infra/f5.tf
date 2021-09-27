resource "google_compute_instance" "f5-instance" {
  name         = var.f5_name
  machine_type = var.f5_machine
  zone         = var.zones[0]
  hostname = "f5.int.rvloona.com"
  tags = ["f5-lb"]

  boot_disk {
    device_name = "boot"
    initialize_params {
      image = format("projects/f5-7626-networks-public/global/images/${var.f5_version}")
      type = "pd-ssd"
      size = "50"
    }
  }

  network_interface {
    network = google_compute_network.app.id
    subnetwork = google_compute_subnetwork.f5-sub.id
    network_ip = var.app_static
    access_config {
      nat_ip = google_compute_address.f5-app-static-external.address
    }
  }

  network_interface {
    network = google_compute_network.mgmt.id
    subnetwork = google_compute_subnetwork.f5-mgmt-sub.id
    network_ip = var.mgmt_static
    access_config {
      nat_ip = google_compute_address.f5-mgmt-static-external.address
    }
  }

  can_ip_forward = true

  metadata_startup_script = file("start.sh")
}