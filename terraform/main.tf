terraform {
  backend "local" {
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.14.1"
    }
  }
}
provider "google" {
  project = var.project_name
  region  = "us-central1"
}

resource "google_service_account" "this" {
    account_id = var.demo_alias
}

resource "google_storage_bucket" "this" {
    name = var.bucket_name
    location = "US"
    force_destroy = true

    # For a production system we'd probably be more careful about eg. data retention settings
    # but for a simple demo we can just let jesus take the wheel
}

resource "google_storage_bucket_iam_member" "this" {
    bucket = google_storage_bucket.this.name
    role = "roles/storage.admin"
    member = google_service_account.this.member
}

resource "google_bigquery_dataset" "this" {
    dataset_id = var.bigquery_dataset_name
    location = "US"
    delete_contents_on_destroy = true
}

resource "google_bigquery_dataset_iam_member" "this" {
    dataset_id = google_bigquery_dataset.this.dataset_id
    role = "roles/bigquery.dataEditor"
    member = google_service_account.this.member
}

resource "google_bigquery_table" "this" {
    dataset_id = google_bigquery_dataset.this.dataset_id
    table_id = "raw_llm_logs"
    deletion_protection = false  # normally risky; this is for convenience in the demo
    schema = <<EOF
[
{"name": "created", "type": "TIMESTAMP", "mode": "NULLABLE"},
{"name": "model", "type": "STRING", "mode": "NULLABLE"},
{"name": "stream", "type": "BOOLEAN", "mode": "NULLABLE"},
{"name": "max_tokens", "type": "INT64", "mode": "NULLABLE"},
{"name": "temperature", "type": "FLOAT64", "mode": "NULLABLE"},
{"name": "type", "type": "STRING", "mode": "NULLABLE"},
{"name": "metrics", "type": "RECORD", "mode": "NULLABLE",
 "fields": [
             {"name": "end", "type": "FLOAT64", "mode": "NULLABLE"},
             {"name": "start", "type": "FLOAT64", "mode": "NULLABLE"},
             {"name": "tokens", "type": "INT64", "mode": "NULLABLE"},
             {"name": "prompt_tokens", "type": "INT64", "mode": "NULLABLE"},
             {"name": "completion_tokens", "type": "INT64", "mode": "NULLABLE"},
             {"name": "time_to_first_token", "type": "FLOAT64", "mode": "NULLABLE"}
            ]}
]
EOF
}

resource "google_storage_bucket_object" "function_source" {
    name = "ingest_json.zip"
    bucket = google_storage_bucket.this.name
    source = "../src/ingest_json/ingest_json.zip"
}

resource "google_cloudfunctions_function" "this" {
    name = "${var.demo_alias}-ingest"
    runtime = "python310"
    source_archive_bucket = google_storage_bucket.this.name
    source_archive_object = google_storage_bucket_object.function_source.name
    service_account_email = google_service_account.this.email
    entry_point = "main"

    event_trigger {
        event_type = "google.storage.object.finalize"
        resource = google_storage_bucket.this.name
    }

    environment_variables = {
      PROJECT_NAME = var.project_name
      DATASET_NAME = google_bigquery_dataset.this.dataset_id
      TABLE_NAME = google_bigquery_table.this.table_id
    }
}