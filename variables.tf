variable "project_id" {
  description = "The project id to create resources in"
  type        = string
}

variable "name" {
  description = "The name to use for resources managed.  The value serves as a common prefix."
  type        = string
  default     = "github-runner"
}

variable "github-runner-url" {
  description = "The source URL used to install the github-runner onto the VM host os.  Passed to curl via cloud-config runcmd."
  type        = string
  default     = "https://github.com/actions/runner/releases/download/v2.273.5/actions-runner-linux-x64-2.273.5.tar.gz"
}

variable "github-url" {
  description = "The URL used to register the instance"
  type        = string
  default     = "https://github.com/openinfrastructure/platform"
}

variable "registration_token" {
  description = "The registration token used to register this runner"
  type        = string
  default     = ""
}

variable "label-list" {
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

variable "os_image" {
  description = "The OS image for VM instances"
  type        = string
  default     = "cos-cloud/cos-stable"
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
  default     = 3
}

variable "hc_timeout" {
  description = "Health check, timeout in seconds."
  type        = number
  default     = 2
}

variable "hc_healthy_threshold" {
  description = "A so-far unhealthy instance will be marked healthy after this many consecutive successes. The default value is 2."
  type        = number
  default     = 2
}

variable "hc_unhealthy_threshold" {
  description = "A so-far healthy instance will be marked unhealthy after this many consecutive failures. The default value is 2."
  type        = number
  default     = 2
}

variable "hc_port" {
  description = "Health check port"
  type        = string
  default     = "9252"
}

variable "hc_path" {
  description = "Health check, the http path to check."
  type        = string
  default     = "/metrics"
}

variable "tags" {
  description = "Additional network tags added to instances.  Intended for opening VPC firewall access for health checks."
  type        = string
  default     = ["allow-health-check"]
}

variable "update_policy_type" {
  description = "The type of update. Valid values are 'OPPORTUNISTIC', 'PROACTIVE'"
  type        = string
  default     = "OPPORTUNISTIC"
}

variable "automatic_restart" {
  description = "If true, automatically restart instances on maintenance events.  See https://cloud.google.com/compute/docs/instances/live-migration#autorestart"
  type        = bool
  default     = false
}

variable "preemptible" {
  description = "If true, create preemptible VM instances intended to reduce cost.  Note, the MIG will recreate pre-empted instnaces.  See https://cloud.google.com/compute/docs/instances/preemptible"
  type        = bool
  default     = true
}
