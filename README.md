# Zabbix in docker

## Quickstart

### (Optional) running postgresql in docker
```sh
docker run -d --name pg postgres
docker exec -it postgres bash -c '
createuser zabbix -U postgres
createdb zabbix -O zabbix -U postgres
'
```

### (Optional) building the images
```sh
git clone git@github.com:ikatson/docker-zabbix.git
cd docker-zabbix

docker build -t ikatson/zabbix-server zabbix-server
docker build -t ikatson/zabbix-frontend zabbix-frontend
```

### Running the server
```sh
docker run -it --rm -e PGHOST=pg --link postgres:pg --name zabbix-server ikatson/zabbix-server
```

### Running the frontend

After you run this for the first time, the default username will be ```Admin``` and the password will be ```zabbix```.

```sh
docker run -it --rm -e PGHOST=pg --link postgres:pg -p 80:80 --link zabbix-server:zabbix-server ikatson/zabbix-frontend
```

### All the rest
TO-DO. I'm still exploring zabbix.
