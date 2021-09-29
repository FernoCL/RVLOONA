resource "google_compute_instance" "control-plane-nodes" {
  count = length(var.zones)
  name = "control-plane-${count.index}"
  machine_type = var.control_machine
  zone  = var.zones[count.index]
  tags = ["control"]

  boot_disk {
    device_name = "boot"
    initialize_params {
      image = "projects/${var.project_id}/global/images/control-plane"
      type = "pd-ssd"
    }
  }

  network_interface {
    network = google_compute_network.app.id
    subnetwork = google_compute_subnetwork.control-sub.id
    network_ip = var.control_ip[count.index]
    access_config {
    }
  }
  can_ip_forward = true
  allow_stopping_for_update = true
}


resource "google_dns_record_set" "control-plane-internal" {
  count = length(var.zones)
  managed_zone = google_dns_managed_zone.rvloona-internal.name
  name         = "control-${count.index}.internal.rvloona.com."
  type         = "A"
  rrdatas      = [ "${resource.google_compute_instance.control-plane-nodes.*.network_interface[count.index][0].network_ip}" ]
  ttl          = 300
}