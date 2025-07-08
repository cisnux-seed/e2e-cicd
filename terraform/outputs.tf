output "cloud_run_url" {
  value = google_cloud_run_service.greedy.status[0].url
}