reset:
	docker-compose down -v
	sudo rm -rf data/minio

strip-configs:
	yq eval '... comments=""' ./rootfs/etc/loki/loki-local-config.yaml > ./rootfs/etc/loki/loki-local-config-stripped.yaml
