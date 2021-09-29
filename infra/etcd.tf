resource "google_compute_instance" "etcd-nodes" {
  count = length(var.zones)
  name = "etcd-${count.index}"
  machine_type = var.etcd_machine
  zone  = var.zones[count.index]
  tags = ["etcd"]

  boot_disk {
    device_name = "boot"
    initialize_params {
      image = "projects/${var.project_id}/global/images/etcd"
      type = "pd-ssd"
    }
  }

  network_interface {
    network = google_compute_network.app.id
    subnetwork = google_compute_subnetwork.etcd.id
    network_ip = var.etcd_ip[count.index]
    access_config {
    }
  }
  can_ip_forward = true
}


resource "google_dns_record_set" "etcd-internal" {
  count = length(var.zones)
  managed_zone = google_dns_managed_zone.rvloona-internal.name
  name         = "etcd-${count.index}.internal.rvloona.com."
  type         = "A"
  rrdatas      = [ "${resource.google_compute_instance.etcd-nodes.*.network_interface[count.index][0].network_ip}" ]
  ttl          = 300
}