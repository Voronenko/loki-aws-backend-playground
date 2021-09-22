# Loki playground with aws S3/DynamoDB backend

## Managing docker loki driver

### Installing
The Docker plugin must be installed on each Docker host that will be running containers you want to collect logs from.

```sh
docker plugin install grafana/loki-docker-driver:latest --alias loki --grant-all-permissions
```

To check installed plugins

```sh
docker plugin ls
ID                  NAME         DESCRIPTION           ENABLED
ac720b8fcfdb        loki         Loki Logging Driver   true
```
Once the plugin is installed it can be configured.

### Upgrade

```sh
docker plugin disable loki --force
docker plugin upgrade loki grafana/loki-docker-driver:latest --grant-all-permissions
docker plugin enable loki
systemctl restart docker
```

### Uninstall

```sh
docker plugin disable loki --force
docker plugin rm loki
```

## Redirecting logs to primary loki instance

Switching from driver: local to driver loki, allows redirection of the container logs to specific loki instance.

```
x-compose-logging: &compose-logging
  logging:
    # Leave local for classic log
    # driver: local
     driver: loki
     options:
       loki-url: "http://172.19.0.4:3100/loki/api/v1/push"
```

## Exposed services

### Minio S3 management console

https://minio.lvh.voronenko.net/

Also ports 9000 for S3 endpoint, 10000 for console

### DynamoDB Web UI

https://dynamodb.lvh.voronenko.net/

also port 7777

## Accessing Minio with aws cli

`~/.aws/config` entry might look as

```
[profile minio]
region = us-east-1
s3 =
    signature_version = s3v4
```

and `~/.aws/credentials` credentials entry might look as

```
[minio]
aws_access_key_id = user
aws_secret_access_key = password
```

If you set everything properly, you can

list buckets

```sh
aws --endpoint-url http://minio.lvh.voronenko.net:9000 s3 ls
```

list files

```sh
aws --endpoint-url http://minio.lvh.voronenko.net:9000 s3 ls s3://chunks
```

create buckets

```sh
aws --endpoint-url http://minio.lvh.voronenko.net:9000 s3 mb s3://mybucket
```

add some objects to bucket

```sh
aws --endpoint-url http://minio.lvh.voronenko.net:9000 s3 cp docker-compose.yml s3://mybucket
```

## Known issues

### Large number of small files in S3 bucket

Check https://grafana.com/docs/loki/latest/best-practices/. You most likely have high cardinality labels, leading to too many streams (and therefore many small objects in your object store).

You can use

$ logcli series --analyze-labels '{}'
to check the cardinality of your labels and the number of streams.
