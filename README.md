# Loki playground with aws S3/DynamoDB backend

## Intro

By default – Loki will store data inside its container / instance, usually under /tmp/loki directory.

For purposes of the current demo, we are emulating S3 with Minio S3 compatible storage, and DynamoDB
with native Amazon's Dynamodb.local.

On that database we will need to create a table, called `loki_index` with primary key h(string)
and sort key named r(BinaryType) - note it is same as index/prefix in storage config for s3.

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

## Scope of the demo.

Demo illustrates running loki in two different modes:

### S3 + DynamoDB

In that scenario - log chunks are stored on a AWS S3 compatible storage, and index is stored in AWS DocumentDB.
Corresponding configuration file `rootfs/etc/loki/loki-local-config-dynamodb.yml`

Presence of the DynamoDB, which also adds additional cost of ownership might be additional point to consider.

### Pure S3 using BoltDB Shipper

BoltDB Shipper lets you run Loki without any dependency on NoSQL stores for storing index. It locally stores the index in BoltDB files instead and keeps shipping those files to a shared object store i.e the same object store which is being used for storing chunks. It also keeps syncing BoltDB files from shared object store to a configured local directory for getting index entries created by other services of same Loki cluster. This helps run Loki with one less dependency and also saves costs in storage since object stores are likely to be much cheaper compared to cost of a hosted NoSQL store or running a self hosted instance of Cassandra.

Corresponding configuration file `rootfs/etc/loki/loki-local-config.yml`

## Known issues

### Large number of small files in S3 bucket

Check https://grafana.com/docs/loki/latest/best-practices/. You most likely have high cardinality labels, leading to too many streams (and therefore many small objects in your object store).

You can use

$ logcli series --analyze-labels '{}'
to check the cardinality of your labels and the number of streams.


### Strange errors can't flush...

```
caller=flush.go:118 org_id=fake msg=”failed to flush user” err=”NoCredentialProviders: no valid providers in chain. Deprecated.\n\tFor verbose messaging see aws.Config.CredentialsChainVerboseErrors”
```

In current demo this can be supressed by Solved using the same ACCESS:SECRET key pair for both S3 and DynamoDB configs.


###  Access denied during syncing tables

Related issue: https://github.com/grafana/loki/issues/2868

```
msg=""error syncing tables"" err=""AccessDenied: Access Denied
\tstatus code: 403, request id: 13650B3B4BBE6387, host id: 82wYupHP/XAKe66FDSAlEwlfTju5D8mRobyDx2G0BccSkK22q5pXbyWF2Qwtn8OAgj+i5OH7br8="""
```

Quite strange workaround:

```
So instead of s3://endpoint/bucket it should rather be https://endpoint:443/bucket
```
