resource "google_container_cluster" "primary" {
  name = "lsdev"
  location = "europe-north1-a"

  node_pool {
    name       = "builtin"
  }
  lifecycle {
    ignore_changes = [ node_pool ]
  }
}

resource "google_container_node_pool" "preemptible" {
  name       = "preemptible"
  cluster    = google_container_cluster.primary.id
  initial_node_count = 1
  autoscaling {
    min_node_count = 1
    max_node_count = 5
  }
  node_config {
    preemptible  = true
    machine_type = "e2-highcpu-4"
  }
}

resource "google_container_node_pool" "ondemand" {
  name       = "ondemand"
  cluster    = google_container_cluster.primary.id
  autoscaling {
    min_node_count = 0
    max_node_count = 3
  }
  node_config {
    preemptible  = false
    machine_type = "e2-highcpu-4"
  }
}