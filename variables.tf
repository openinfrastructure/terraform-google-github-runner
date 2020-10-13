variable "project_id" {
  description = "The project id to create resources in"
  type        = string
}

variable "name" {
  description = "The name to use for resources managed.  The value serves as a common prefix."
  type        = string
  default     = "github-runner"
}

variable "runner_url" {
  description = "The source URL used to install the github-runner onto the VM host os.  Passed to curl via cloud-config runcmd."
  type        = string
  default     = "https://github.com/actions/runner/releases/download/v2.273.5/actions-runner-linux-x64-2.273.5.tar.gz"
}

variable "github_url" {
  description = "The URL used to register the instance, for example https://github.com/myorg/myrepo"
  type        = string
}

variable "registration_token" {
  description = "The registration token used to register this runner"
  type        = string
  default     = ""
}

variable "labels" {
  description = "Assign labels to this runner.  See https://docs.github.com/en/free-pro-team@latest/actions/hosting-your-own-runners/using-labels-with-self-hosted-runners"
  type        = list
  default     = ["docker", "gcp"]
}

variable "service_account_email" {
  description = "The service account bound to the instances.  If unset, set to <name>@<projed_id>.iam.gserviceaccount.com"
  type        = string
  default     = null
}

variable "region" {
  description = "The region to deploy resources into."
  type        = string
  default     = "us-west1"
}

variable "zones" {
  description = "The zones in the region to distribute instances across.  If empty, all available zones in the region are used."
  type        = list(string)
  default     = []
}

variable "image_project" {
  description = "The image project used with the MIG instance template"
  type        = string
  default     = "centos-cloud"
}

variable "image_name" {
  description = "The image name used with the MIG instance template.  If the value is the empty string, image_family is used instead."
  type        = string
  default     = ""
}

variable "disk_size_gb" {
  description = "The size in GB of the primary disk for each image"
  type        = string
  default     = "100"
}

variable "image_family" {
  description = "Configures templates to use the latest non-deprecated image in the family at the point Terraform apply is run.  Used only if image_name is empty."
  type        = string
  default     = "centos-8"
}

variable "subnetwork" {
  description = "The name of the subnet the primary interface each instance will use.  Do not specify as a fully qualified name."
  type        = string
  default     = "default"
}

variable "subnetwork_project" {
  description = "The project hosting the subnet"
  type        = string
  default     = null
}

variable "machine_type" {
  description = "The machine type"
  type        = string
  default     = "e2-standard-2"
}

variable "num_instances" {
  description = "The number of instances in the instance group"
  type        = number
  default     = 1
}

variable "hc_initial_delay_secs" {
  description = "The number of seconds that the managed instance group waits before it applies autohealing policies to new instances or recently recreated instances."
  type        = number
  default     = 60
}

variable "hc_interval" {
  description = "Health check, check interval in seconds."
  type        = number
  default     = 10
}

variable "hc_timeout" {
  description = "Health check, timeout in seconds."
  type        = number
  default     = 5
}

variable "hc_healthy_threshold" {
  description = "A so-far unhealthy instance will be marked healthy after this many consecutive successes."
  type        = number
  default     = 2
}

variable "hc_unhealthy_threshold" {
  description = "A so-far healthy instance will be marked unhealthy after this many consecutive failures."
  type        = number
  default     = 3
}

variable "hc_port" {
  description = "Health check port."
  type        = string
  default     = "9000"
}

variable "hc_path" {
  description = "Health check, the http path to check."
  type        = string
  default     = "/status.json"
}

variable "tags" {
  description = "Additional network tags added to instances.  Intended for opening VPC firewall access for health checks."
  type        = list(string)
  default     = ["allow-health-check"]
}

variable "update_policy_type" {
  description = "The type of update. Valid values are 'OPPORTUNISTIC', 'PROACTIVE'"
  type        = string
  default     = "OPPORTUNISTIC"
}

variable "preemptible" {
  description = "If true, create preemptible VM instances intended to reduce cost.  Note, the MIG will recreate pre-empted instnaces.  See https://cloud.google.com/compute/docs/instances/preemptible"
  type        = bool
  default     = true
}
