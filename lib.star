PLACEHOLDER_BUCKET_PULLING_SERVICE_NAME_PREFIX = "placeholder-bucket-puller-"
RCLONE_IMAGE = "rclone/rclone:1.55.1"


def directories_from_s3_buckets(plan, prebaked_directories, timeout_per_bucket="6h"):
    """
    a function to pull in s3 buckets into persistent directories
    prebaked_directories: a map from persitent key to prebaked_directory object
    timeout_per_bucket: defaults to 6h, the time to wait for something to finish downloading
    """
    index = 0
    for persistent_key, prebaked_directory in prebaked_directories.items():
        plan.add_service(
            name=PLACEHOLDER_BUCKET_PULLING_SERVICE_NAME_PREFIX + str(index),
            config=ServiceConfig(
                image=RCLONE_IMAGE,
                cmd=[
                    "rclone copy -P {0} ".format(prebaked_directory.bucket)
                    + prebaked_directory.path
                    + " && touch /tmp/finished && tail -f /dev/null",
                ],
                entrypoint=["/bin/sh", "-c"],
                files={
                    prebaked_directory.path: Directory(
                        persistent_key=persistent_key, size=prebaked_directory.size
                    )
                },
                env_vars={
                    "RCLONE_CONFIG_MYS3_TYPE": "s3",
                    "RCLONE_CONFIG_MYS3_PROVIDER": prebaked_directory.s3_provider,
                    "RCLONE_CONFIG_MYS3_ENDPOINT": prebaked_directory.s3_endpoint,
                },
                node_selectors=prebaked_directory.node_selectors,
            ),
        )
        index += 1

    plan.print(
        "Started creating {0} persistent directories".format(len(prebaked_directories))
    )

    for index in range(0, len(prebaked_directories)):
        plan.wait(
            service_name=PLACEHOLDER_BUCKET_PULLING_SERVICE_NAME_PREFIX + str(index),
            recipe=ExecRecipe(command=["cat", "/tmp/finished"]),
            field="code",
            assertion="==",
            target_value=0,
            interval="1s",
            timeout=timeout_per_bucket,  # 6 hours should be enough for the biggest network
        )

    return prebaked_directories.keys()


def new_prebaked_directory(
    bucket, size, path, s3_provider, s3_endpoint, node_selectors=None
):
    """
    a prebaked directory object
    bucke: the s3 bucket
    size: the size in megabytes
    path: the path at which to mount and write the data
    node_selectors: ignored on Docker; if you want the PV to attach to a Pod; use this on k8s
    s3_provider: the provider of s3
    s3_endpoint: the s3 url
    """

    if node_selectors == None:
        node_selectors = {}
    return struct(
        bucket=bucket,
        size=size,
        path=path,
        s3_provider=s3_provider,
        s3_endpoint=s3_endpoint,
        node_selectors=node_selectors,
    )
