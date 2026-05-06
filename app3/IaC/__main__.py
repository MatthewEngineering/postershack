import pulumi
import pulumi_gcp as gcp

cfg = pulumi.Config()
project = gcp.config.project
region = gcp.config.region or "us-central1"
app_name = cfg.get("app_name") or "postershack-app3"
max_instances = cfg.get_int("max_instances") or 1
hf_token_value = cfg.require_secret("hf_token")

# ── Artifact Registry ─────────────────────────────────────────────────────────

artifact_repo = gcp.artifactregistry.Repository(
    "images",
    location=region,
    repository_id="postershack",
    format="DOCKER",
)

# ── GCS bucket ────────────────────────────────────────────────────────────────

bucket = gcp.storage.Bucket(
    "images",
    name=pulumi.Output.concat(project, "-postershack-images"),
    location=region,
    force_destroy=False,
    uniform_bucket_level_access=True,
    lifecycle_rules=[
        gcp.storage.BucketLifecycleRuleArgs(
            condition=gcp.storage.BucketLifecycleRuleConditionArgs(age=90),
            action=gcp.storage.BucketLifecycleRuleActionArgs(type="Delete"),
        )
    ],
)

# ── Secrets ───────────────────────────────────────────────────────────────────

hf_token_secret = gcp.secretmanager.Secret(
    "hf-token",
    secret_id="hf-token",
    replication=gcp.secretmanager.SecretReplicationArgs(
        auto=gcp.secretmanager.SecretReplicationAutoArgs(),
    ),
)

hf_token_version = gcp.secretmanager.SecretVersion(
    "hf-token-version",
    secret=hf_token_secret.id,
    secret_data=hf_token_value,
)

# ── Cloud Run service account ─────────────────────────────────────────────────

cloud_run_sa = gcp.serviceaccount.Account(
    "cloud-run-sa",
    account_id=f"{app_name}-cr",
    display_name=f"Cloud Run runtime SA for {app_name}",
)

gcp.artifactregistry.RepositoryIamMember(
    "cloud-run-ar-reader",
    repository=artifact_repo.name,
    location=artifact_repo.location,
    role="roles/artifactregistry.reader",
    member=cloud_run_sa.email.apply(lambda e: f"serviceAccount:{e}"),
)

gcp.secretmanager.SecretIamMember(
    "cloud-run-hf-token-accessor",
    secret_id=hf_token_secret.secret_id,
    role="roles/secretmanager.secretAccessor",
    member=cloud_run_sa.email.apply(lambda e: f"serviceAccount:{e}"),
)

gcp.storage.BucketIAMMember(
    "cloud-run-storage-user",
    bucket=bucket.name,
    role="roles/storage.objectUser",
    member=cloud_run_sa.email.apply(lambda e: f"serviceAccount:{e}"),
)

# ── Cloud Run service ─────────────────────────────────────────────────────────

image = pulumi.Output.concat(
    region, "-docker.pkg.dev/", project, "/postershack/app3:latest"
)

cloud_run_service = gcp.cloudrunv2.Service(
    "app",
    name=app_name,
    location=region,
    ingress="INGRESS_TRAFFIC_ALL",
    template=gcp.cloudrunv2.ServiceTemplateArgs(
        service_account=cloud_run_sa.email,
        scaling=gcp.cloudrunv2.ServiceTemplateScalingArgs(
            min_instance_count=0,
            max_instance_count=max_instances,
        ),
        containers=[
            gcp.cloudrunv2.ServiceTemplateContainerArgs(
                # Placeholder — CI/CD overwrites the tag on first push.
                image=image,
                ports=[
                    gcp.cloudrunv2.ServiceTemplateContainerPortArgs(
                        container_port=7860,
                    )
                ],
                envs=[
                    gcp.cloudrunv2.ServiceTemplateContainerEnvArgs(
                        name="GRADIO_SERVER_NAME",
                        value="0.0.0.0",
                    ),
                    gcp.cloudrunv2.ServiceTemplateContainerEnvArgs(
                        name="GRADIO_SERVER_PORT",
                        value="7860",
                    ),
                    gcp.cloudrunv2.ServiceTemplateContainerEnvArgs(
                        name="STORAGE_MODE",
                        value="gcs",
                    ),
                    gcp.cloudrunv2.ServiceTemplateContainerEnvArgs(
                        name="GCS_BUCKET_NAME",
                        value=bucket.name,
                    ),
                    gcp.cloudrunv2.ServiceTemplateContainerEnvArgs(
                        name="HF_TOKEN",
                        value_source=gcp.cloudrunv2.ServiceTemplateContainerEnvValueSourceArgs(
                            secret_key_ref=gcp.cloudrunv2.ServiceTemplateContainerEnvValueSourceSecretKeyRefArgs(
                                secret=hf_token_secret.secret_id,
                                version="latest",
                            ),
                        ),
                    ),
                ],
                resources=gcp.cloudrunv2.ServiceTemplateContainerResourcesArgs(
                    limits={"cpu": "1", "memory": "2Gi"},
                ),
            )
        ],
    ),
)

gcp.cloudrunv2.ServiceIamMember(
    "public-invoker",
    name=cloud_run_service.name,
    location=cloud_run_service.location,
    role="roles/run.invoker",
    member="allUsers",
)

# ── Outputs ───────────────────────────────────────────────────────────────────

pulumi.export("service_url", cloud_run_service.uri)
pulumi.export(
    "service_fqdn",
    cloud_run_service.uri.apply(lambda u: u.replace("https://", "")),
)
pulumi.export(
    "ar_image_base",
    pulumi.Output.concat(region, "-docker.pkg.dev/", project, "/postershack/app3"),
)
pulumi.export("gcs_bucket_name", bucket.name)
