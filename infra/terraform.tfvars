project_id = "bamboleo"
region = "us-central1"
zones = [
  "us-central1-a",
  "us-central1-c",
  "us-central1-f"
]

#Network Config
mgmt-net = "f5-mgmt"
app-net = "rvloona"

mgmt_cidr = "10.1.1.0/29"
app_cidr = "10.1.2.0/29"
control_cidr = "10.1.3.0/29"
etcd_cidr = "10.1.4.0/29"
nodes_cidr = "10.2.0.0/16"

mgmt_static = "10.1.1.2"
app_static = "10.1.2.2"

#F5 Config
f5_name = "f5-rvloona"
f5_machine = "n1-standard-4"
# Get more versions with gcloud compute images list --project f5-7626-networks-public | grep f5
f5_version = "f5-bigip-16-1-2-1-0-0-10-payg-good-25mbps-211222200353"

#etcd Config
etcd_machine = "n1-standard-1"
etcd_ip = [
  "10.1.4.2",
  "10.1.4.3",
  "10.1.4.4"
]

#control Config
control_machine = "n1-standard-2"

control_ip = [
  "10.1.3.2",
  "10.1.3.3",
  "10.1.3.4"
]

#nodes Config
node_machine = "n1-standard-4"

node_ip = [
  "10.2.0.2",
  "10.2.0.3",
  "10.2.0.4"
]