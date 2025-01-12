# End-to-end Data Pipeline

## Introduction

This repo implements a simple analytics pipeline that ingests JSON data to a BigQuery table, does some simple SQL transformations, and produces some simple visualizations. The solution is intended to be relatively self-contained and doesn't require registering for any cloud services or SaaS vendors, aside from a Google Cloud project.  This constraint drives some of our architecture/tool selection choices, as discussed below.

## Architecture Overview

The solution consists of a relatively small number of components, selected with the aim of making this project self-contained and easily deployable from the command line:

- **Ingestion and Data Storage** is done entirely in Google Cloud and configured via Terraform.  The TF configuration in this project creates:
  - A Cloud Storage bucket to hold the raw data
  - A BigQuery dataset and table to hold the ingested data
  - A Cloud Function, triggered by files being uploaded to the bucket, that reads the given JSON data from the bucket and inserts into the BigQuery table
  - A GCP service account and associated IAM resources to manage permissions on the above
  - *Note:* This Terraform configuration maintains state *locally*, so don't run the same project configuration on multiple computers. In production we'd want to maintain state in object storage in the cloud somewhere.
- **Transformation** is done via dbt
  - In this particular case, transformations are relatively simple, so its inclusion here is mostly illustrative.
  - The net output of the transformation is a table in the same BigQuery dataset, called `llm_usage`, that can be queried downstream.
- **Visualization** is done via evidence.dev
  - This is simultaneously a heavy-handed choice (in terms of installation requirements) and overly lightweight on the BI layer (it's basically a notebook that runs SQL in this case), but I chose Evidence because I wanted something that can be run entirely locally, as opposed to needing a SaaS account/subscription or some containerization solution.
  - In a "production" environment, we'd be connecting a BI tool (eg. Looker, Lightdash, Metabase, Superset/Preset) to the BigQuery instance, and depending on the BI tool chosen, the metrics modelling can be done in dbt or in the BI layer.

## Prerequisites
To run this pipeline locally, you'll need to install
- The `gcloud` CLI utility
  - Most authentication in the project uses application default credentials.  Invoke `gcloud auth application-default login` to set that up, or set up environment variables as you like to manage the auth.
- Terraform
  - I suggest to install Terraform using [tfenv](https://github.com/tfutils/tfenv)
  - This configuration was tested using Terraform version 1.10.4
- NPM
  - I suggest to install NPM using [NVM](https://github.com/nvm-sh/nvm)
  - This configuration was tested using node v22.13.0 and npm 10.9.2
- dbt
  - Install this via pip (use a Python environment if you want)
  - Install both `dbt-core` and `dbt-bigquery`
  - This configuration was tested using dbt-core v1.9.1 and dbt-bigquery v1.9.1 running Python 3.10.16
Again, this setup seems heavy-handed, but this is because I want to make this project as self-contained as possible with a minimum of live vendor dependencies.

## Install and Run
- Set up the ingestion pipeline
  - Copy `variables.tf.example` to `variables.tf`
    - Put in your GCP project name, as well as a bucket name where this project will put resources
    - These two variables are *globally* unique, which is why I don't prepopulate this for you
    - The other variables are locally namespaced, so their default values can be left as-is
  - Ensure you're logged into GCP (`gcloud auth application-default login`) and have Terraform installed and active
  - From the `terraform` subdirectory, run:
```
terraform init
terraform apply
```
  - Inspect the Terraform plan to see what's being created, and enter `yes` if these resources look OK to you.
  - Applying the plan will take a few minutes since it involves deploying a Cloud function
  - After this is done, there will be an empty table in the `pipeline_demo` BigQuery dataset.
- Add data
  - Navigate to the Cloud Storage bucket created by Terraform and create a `data/` folder
  - Drag-and-drop the `llm_logs.json` input data to that bucket and folder
  - The finalization (ie. upload) of the object should trigger the Cloud Function to run.
    - Inspect the Cloud Function logs if you want to make sure the function runs OK.
  - After this is done, the table `pipeline_demo.raw_llm_logs` should contain the data as-ingested.
- Transform the data
  - Navigate to the `dbt` subdirectory of this repository
  - Copy `profiles.yml.example` to `~/.dbt/profiles.yml`, and edit the `project:` value to contain your GCP project ID.
  - Invoke `dbt run` from the `dbt subdirectory`
  - This should create two tables in the `pipeline_demo` BigQuery dataset.  `pipeline_demo.llm_usage` is the "output", transformed table.
  - This is still pretty granular, per-prompt level data. I don't think pre-aggregation is needed in the transformation layer, and we should do it in the presentation layer instead given the excellent performance of BigQuery at scale.
- Visualize the data
  - Navigate to the `evidence` subdirectory of this repository
  - Run the following:
```
npm install
npm run sources
npm run dev
```
  - This will start a web server on localhost:3000 that is running Evidence, which serves flavoured Markdown inside the `evidence/pages` directory. Markdown pages corresponding to particular data visualziations can be created and edited there.
  - Obviously this visualization option isn't really for production purposes -- we'd want to deploy this to cloud infrastructure or run some other sort of BI tool in reality.
  - Ctrl-C to exit the dev web server.
- Cleaning up
  - Inside the `terraform` subdirectory, run `terraform destroy` and confirm destruction of the cloud resources created for this demo.