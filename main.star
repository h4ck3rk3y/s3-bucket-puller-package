lib = import_module("./lib.star")


def run(plan):
    prebaked_directory = lib.new_prebaked_directory(
        "mys3:ethpandaops-ethereum-node-snapshots/ephemery/geth/latest",
        5000,
        "/data/geth/execution-data",
        "DigitalOcean",
        "https://ams3.digitaloceanspaces.com",
    )

    prebaked_directories = lib.directories_from_s3_buckets(
        plan,
        prebaked_directories={"my-prebaked-directory": prebaked_directory},
    )

    prebaked_directory_persistent_key = prebaked_directories[0]
    plan.add_service(
        name="test-service",
        config=ServiceConfig(
            image="badouralix/curl-jq",
            files={
                prebaked_directory.path: Directory(
                    persistent_key=prebaked_directory_persistent_key,
                    size=prebaked_directory.size,
                )
            },
        ),
    )

    plan.wait(
        service_name="test-service",
        recipe=ExecRecipe(command=["ls", prebaked_directory.path]),
        field="code",
        assertion="==",
        target_value=0,
        interval="1s",
        timeout="1m",  # 6 hours should be enough for the biggest network
    )
