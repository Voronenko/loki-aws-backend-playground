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

