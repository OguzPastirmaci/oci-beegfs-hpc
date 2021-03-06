/*
All network resources for this template
*/

resource "oci_core_virtual_network" "beegfs" {
  cidr_block = "${var.vpc_cidr}"
  compartment_id = "${var.compartment_ocid}"
  display_name = "beegfs"
  dns_label = "beegfs"
}

resource "oci_core_internet_gateway" "internet_gateway" {
  compartment_id = "${var.compartment_ocid}"
  display_name = "internet_gateway"
  vcn_id = "${oci_core_virtual_network.beegfs.id}"
}

resource "oci_core_route_table" "pubic_route_table" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id = "${oci_core_virtual_network.beegfs.id}"
  display_name = "RouteTableForComplete"
  route_rules {
    cidr_block = "0.0.0.0/0"
    network_entity_id = "${oci_core_internet_gateway.internet_gateway.id}"
  }
}


resource "oci_core_nat_gateway" "nat_gateway" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.beegfs.id}"
  display_name   = "nat_gateway"
}


resource "oci_core_route_table" "private_route_table" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.beegfs.id}"
  display_name   = "private_route_tableForComplete"
  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = "${oci_core_nat_gateway.nat_gateway.id}"
  }
}

resource "oci_core_security_list" "public_security_list" {
  compartment_id = "${var.compartment_ocid}"
  display_name = "Public Subnet"
  vcn_id = "${oci_core_virtual_network.beegfs.id}"
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol = "6"
  }
  ingress_security_rules {
    tcp_options {
      max = 22
      min = 22
    }
    protocol = "6"
    source = "0.0.0.0/0"
  }
  ingress_security_rules {
    tcp_options {
      max = 3389
      min = 3389
    }
    protocol = "6"
    source   = "0.0.0.0/0"
  }
}

# https://www.ibm.com/support/knowledgecenter/en/STXKQY_5.0.3/com.ibm.spectrum.scale.v5r03.doc/bl1adv_firewall.htm
resource "oci_core_security_list" "private_security_list" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "Private"
  vcn_id         = "${oci_core_virtual_network.beegfs.id}"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }
  egress_security_rules {
    protocol    = "all"
    destination = "${var.vpc_cidr}"
  }
  ingress_security_rules  {
    tcp_options  {
      max = 443
      min = 443
    }
    protocol = "6"
    source   = "${var.vpc_cidr}"
  }
  ingress_security_rules {
    tcp_options  {
      max = 22
      min = 22
    }
    protocol = "6"
    source   = "${var.vpc_cidr}"
  }
  ingress_security_rules  {
    tcp_options {
      max = 80
      min = 80
    }
    protocol = "6"
    source   = "${var.vpc_cidr}"
  }
  ingress_security_rules  {
    protocol = "all"
    source = "${var.vpc_cidr}"
  }
}


# Regional subnet - public
resource "oci_core_subnet" "public" {
  count = "1"
  cidr_block = "${cidrsubnet(var.vpc_cidr, 8, count.index)}"
  display_name = "public_${count.index}"
  compartment_id = "${var.compartment_ocid}"
  vcn_id = "${oci_core_virtual_network.beegfs.id}"
  route_table_id = "${oci_core_route_table.pubic_route_table.id}"
  security_list_ids = ["${oci_core_security_list.public_security_list.id}"]
  dhcp_options_id = "${oci_core_virtual_network.beegfs.default_dhcp_options_id}"
  dns_label = "public${count.index}"
}


# Regional subnet - private
resource "oci_core_subnet" "private" {
  count                      = "1"
  cidr_block                 = "${cidrsubnet(var.vpc_cidr, 8, count.index+3)}"
  display_name               = "private_${count.index}"
  compartment_id             = "${var.compartment_ocid}"
  vcn_id                     = "${oci_core_virtual_network.beegfs.id}"
  route_table_id             = "${oci_core_route_table.private_route_table.id}"
  security_list_ids          = ["${oci_core_security_list.private_security_list.id}"]
  dhcp_options_id            = "${oci_core_virtual_network.beegfs.default_dhcp_options_id}"
  prohibit_public_ip_on_vnic = "true"
  dns_label                  = "private${count.index}"
}


resource "oci_core_subnet" "privateb" {
  count                      = "1"
  cidr_block                 = cidrsubnet(var.vpc_cidr, 8, count.index + 6)
  display_name               = "privateb_${count.index}"
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_virtual_network.beegfs.id
  route_table_id             = oci_core_route_table.private_route_table.id
  security_list_ids          = [oci_core_security_list.private_security_list.id]
  dhcp_options_id            = oci_core_virtual_network.beegfs.default_dhcp_options_id
  prohibit_public_ip_on_vnic = "true"
  dns_label                  = "privateb${count.index}"
}
