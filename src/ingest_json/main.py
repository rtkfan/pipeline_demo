from google.cloud import bigquery
from google.cloud import storage
import json
import os

def main(event, context):
    """Triggered by a change to a Cloud Storage bucket.
    Args:
         event (dict): Event payload.
         context (google.cloud.functions.Context): Metadata for the event.
    """
    bucket_name = event.get('bucket')
    file_name = event.get('name')

    project_name = os.getenv("PROJECT_NAME")
    dataset_name = os.getenv("DATASET_NAME")
    table_name = os.getenv("TABLE_NAME")

    table_fqn = f'{project_name}.{dataset_name}.{table_name}'

    if not file_name.startswith('data/'): # ignore updates to other resources in this bucket
      print(f'Skipping {file_name}, does not match prefix')
      return
    
    storage_client = storage.Client()
    bq_client = bigquery.Client(project=project_name)

    try:
        bucket = storage_client.bucket(bucket_name)
        blob = bucket.blob(file_name)
        file_contents = blob.download_as_text()
        json_data = json.loads(file_contents)
        rows = json_data['data']
        try:
            errors = bq_client.insert_rows_json(table_fqn, rows)
            if errors:
                print(f"Errors occurred: {errors}")
            else:
                print(f"Uploaded {len(rows)} to {table_fqn}.")
        except Exception as e:
            print(f"Error uploading data: {e}")
    except Exception as e:
      print(f"Error procesing file: {e}")
    
    return