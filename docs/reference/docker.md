---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/docker.html
---

# Running Logstash on Docker [docker]

Docker images for Logstash are available from the Elastic Docker registry. The base image is [Red Hat Universal Base Image 9 Minimal](https://catalog.redhat.com/software/containers/ubi9/ubi-minimal/61832888c0d15aff4912fe0d).

A list of all published Docker images and tags is available at [www.docker.elastic.co](https://www.docker.elastic.co). The source code is in [GitHub](https://github.com/elastic/logstash/tree/master).

These images are free to use under the Elastic license. They contain open source and free commercial features and access to paid commercial features. [Start a 30-day trial](docs-content://deploy-manage/license/manage-your-license-in-self-managed-cluster.md) to try out all of the paid commercial features. See the [Subscriptions](https://www.elastic.co/subscriptions) page for information about Elastic license levels.

## Pulling the image [_pulling_the_image]

Obtaining Logstash for Docker is as simple as issuing a `docker pull` command against the Elastic Docker registry.

However, version 9.0.0 of Logstash has not yet been released, so no Docker image is currently available for this version.


## Verifying the image [_verifying_the_image]

Although it’s optional, we highly recommend verifying the signatures included with your downloaded Docker images to ensure that the images are valid.

Elastic images are signed with [Cosign](https://docs.sigstore.dev/cosign/overview/) which is part of the [Sigstore](https://www.sigstore.dev/) project. Cosign supports container signing, verification, and storage in an OCI registry. Install the appropriate [Cosign application](https://docs.sigstore.dev/cosign/installation/) for your operating system.

Run the following commands to verify the container image signature for {{ls}} v9.0.0-beta1:

Version 9.0.0 of Logstash has not yet been released, so no Docker image is currently available for this version.


