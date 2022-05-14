resource "google_compute_instance" "nodes" {
  count = length(var.zones)
  name = "node-${count.index}"
  machine_type = var.node_machine
  zone  = var.zones[count.index]
  tags = ["node"]

  boot_disk {
    device_name = "boot"
    initialize_params {
      image = "projects/${var.project_id}/global/images/base"
      type = "pd-ssd"
    }
  }

  network_interface {
    network = google_compute_network.app.id
    subnetwork = google_compute_subnetwork.nodes.id
    network_ip = var.node_ip[count.index]
    access_config {
    }
  }
  can_ip_forward = true
}


resource "google_dns_record_set" "node-internal" {
  count = length(var.zones)
  managed_zone = google_dns_managed_zone.rvloona-internal.name
  name         = "node-${count.index}.internal.rvloona.com."
  type         = "A"
  rrdatas      = [ "${resource.google_compute_instance.nodes.*.network_interface[count.index][0].network_ip}" ]
  ttl          = 300
}