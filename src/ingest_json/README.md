This Python script is intended to be invoked from Cloud Functions (1st gen) via a Cloud Storage trigger (object finalization).

We provide a ZIP file of the other items in this directory so that it can be uploaded to Terraform as a storage object, and so we can create the function completely from scratch in Terraform.
- If the function source code is edited, recreate the ZIP file using `zip -0 ingest_json.zip main.py requirements.txt`

If this were a "real" deployment, I'd rather mirror this repo into a Cloud Source repo and deploy the code that way, but that would make this project not self-contained, so I don't want that here!  I think the small size of the ZIP file makes the sin of committing a binary to source control a little more OK...