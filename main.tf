# Copyright 2019 Open Infrastructure Services LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

data "google_compute_image" "img" {
  project = var.image_project
  name    = var.image_name == "" ? null : var.image_name
  family  = var.image_name == "" ? var.image_family : null
}

data "google_compute_zones" "available" {
  project = var.project_id
  region  = var.region
}

locals {
  service_account_email = "${var.service_account_email == "" ? "${var.name}@${var.project_id}" : var.service_account_email}"
  tags                  = var.tags
  label-list            = "${join(",", concat(list(var.name), var.label-list))}"
  subnetwork_project    = "${var.subnetwork_project == "" ? var.project_id : var.subnetwork_project}"
  zones                 = length(var.zones) > 0 ? var.zones : data.google_compute_zones.available.names
}

module "startup-script-lib" {
  source = "git::https://github.com/terraform-google-modules/terraform-google-startup-scripts.git?ref=v1.0.0"
}

data "template_file" "startup-script-config" {
  template = "${file("${path.module}/templates/startup-script-config.tpl")}"
  vars = {
    github-runner-url  = var.github-runner-url
    github-url         = var.github-url
    registration_token = var.registration_token
    tag-list           = local.label-list
  }
}

resource google_compute_instance_template "github-runner" {
  name_prefix  = "${var.name}-"
  machine_type = var.machine_type
  region       = var.region
  project      = var.project_id

  tags = local.tags

  network_interface {
    subnetwork         = var.subnetwork
    subnetwork_project = local.subnetwork_project
  }

  disk {
    auto_delete  = true
    boot         = true
    source_image = data.google_compute_image.img.self_link
    type         = "PERSISTENT"
    disk_size_gb = var.disk_size_gb
  }

  metadata = {
    startup-script        = module.startup-script-lib.content
    startup-script-config = data.template_file.startup-script-config.rendered
    startup-script-custom = file("${path.module}/files/startup-script.sh")
    shutdown-script       = file("${path.module}/files/shutdown-script.sh")
  }

  scheduling {
    preemptible       = var.preemptible
    automatic_restart = var.preemptible ? false : true
  }

  lifecycle {
    create_before_destroy = true
  }

  service_account {
    email  = local.service_account_email
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_region_instance_group_manager" "runner" {
  project  = var.project_id
  name     = var.name

  base_instance_name = var.name

  region = var.region
  distribution_policy_zones = local.zones

  update_policy {
    type            = var.update_policy_type
    minimal_action  = "REPLACE"
    max_surge_fixed = 3
    min_ready_sec   = 30
  }

  target_size = var.num_instances

  named_port {
    name = "health-check"
    port = var.hc_port
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.github-runner.self_link
    initial_delay_sec = var.hc_initial_delay_secs
  }

  version {
    name              = var.name
    instance_template = google_compute_instance_template.github-runner.self_link
  }
}

resource google_compute_health_check "github-runner" {
  name    = var.name
  project = var.project_id

  check_interval_sec  = var.hc_interval
  timeout_sec         = var.hc_timeout
  healthy_threshold   = var.hc_healthy_threshold
  unhealthy_threshold = var.hc_unhealthy_threshold

  http_health_check {
    port         = var.hc_port
    request_path = var.hc_path
  }
}
