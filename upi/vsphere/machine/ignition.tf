provider "ignition" {
  version = "1.1.0"
}

locals {
  mask = "${element(split("/", var.machine_cidr), 1)}"
  gw   = "10.19.115.254"

  ignition_encoded = "data:text/plain;charset=utf-8;base64,${base64encode(var.ignition)}"
}

data "ignition_file" "hostname" {
  count = "${var.instance_count}"

  filesystem = "root"
  path       = "/etc/hostname"
  mode       = "420"

  content {
    content = "${var.name}-${count.index}"
  }
}

data "ignition_file" "static_ip" {
  count = "${var.instance_count}"

  filesystem = "root"
  path       = "/etc/sysconfig/network-scripts/ifcfg-ens192"
  mode       = "420"

  content {
    content = <<EOF
TYPE=Ethernet
BOOTPROTO=none
NAME=ens192
DEVICE=ens192
ONBOOT=yes
IPADDR=${local.ip_addresses[count.index]}
PREFIX=${local.mask}
GATEWAY=${local.gw}
DOMAIN=${var.cluster_domain}
DNS1=10.19.143.247
DNS2=10.19.143.248
EOF
  }
}

data "ignition_config" "ign" {
  count = "${var.instance_count}"

  append {
    source = "${local.ignition_encoded}"
  }

  files = [
    "${data.ignition_file.hostname.*.id[count.index]}",
    "${data.ignition_file.static_ip.*.id[count.index]}",
  ]
}
