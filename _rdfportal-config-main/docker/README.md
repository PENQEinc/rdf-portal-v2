# Execution environment on rdfp servers

## Servers

* rdfp01, rdfp02 (load balanced)
    * virtuoso

* rdfp04
    * sparql-proxy

## Setup

### rdfp01, rdfp02

```bash
cd virtuoso
./configure
```

Available commands

`make up`: Create and start all containers

`make down`: Stop and remove all containers

`make down-v`: Stop and remove all containers, volumes

`make ps`: List all containers

### rdfp04

```bash
cd sparql-proxy
./configure
make
```

Available commands

`make`: Build image for all containers

`make up`: Create and start all containers

`make down`: Stop and remove all containers

`make down-v`: Stop and remove all containers, volumes

`make ps`: List all containers

`make rebuild`: Stop all containers and rebuild image for all containers

Refer to the [sparql-proxy](https://github.com/dbcls/sparql-proxy) and add the necessary
settings to [common.env](sparql-proxy/common/common.env). (e.g. `ADMIN_PASSWORD`)

## Port settings

| Endpoint     | virtuoso (rdfp01, rdfp02) | sparql-proxy (rdfp04) |
|--------------|--------------------------:|----------------------:|
| primary      |                     11001 |                 10001 |
| ddbj         |                     11002 |                 10002 |
| pdb          |                     11003 |                 10003 |
| kero         |                     11004 |                 10004 |
| ncbi         |                     11005 |                 10005 |
| ebi          |                     11006 |                 10006 |
| sib          |                     11007 |                 10007 |
| pubchem      |                     11008 |                 10008 |
| bioportal    |                     11009 |                 10009 |
| proteinatlas |                     11010 |                 10010 |
| wikidata     |                     11011 |                 10011 |
| covid        |                     11012 |                 10012 |
| med2rdf      |                     11013 |                 10013 |

## Addind a new endpoint

1. Create a `NEW_ENDPOINT.conf` in [nginx/conf.d/endpoints](../nginx/conf.d/endpoints)

    ```
    location /NEW_ENDPOINT/ {
       proxy_pass http://localhost:10***/NEW_ENDPOINT/;
    }
    
    location /backend/NEW_ENDPOINT/ {
       proxy_pass http://backend_NEW_ENDPOINT/;
       proxy_http_version 1.1;
       proxy_set_header Upgrade $http_upgrade;
       proxy_set_header Connection "upgrade";
    }
    ```

2. Add servers to [nginx/upstream.conf](../nginx/upstream.conf)

    ```
    upstream backend_NEW_ENDPOINT {
        least_conn;
        server rdfp01:11***;
        server rdfp02:11***;
    }
    ```

3. Create virtuoso setting

    ```bash
    mkdir virtuoso/NEW_ENDPOINT
    cd virtuoso/NEW_ENDPOINT
    ln -s ../common/docker-compose.yml
    ```

    Then create `.env` and add environment variables used in `docker-compose.yml`.

    ```
    DATA_DIR=/data/rdfportal/virtuoso/NEW_ENDPOINT/database
    HOST_PORT=11***
    VIRT_Parameters_NumberOfBuffers=8170000
    VIRT_Parameters_MaxDirtyBuffers=6000000
    VIRT_Parameters_MaxQueryMem=20G
    ```

    Finally, run the `configure` script to update the `Makefile` created in the [setup section](#setup). 

4. Create sparql-proxy setting

    ```bash
    mkdir sparql-proxy/NEW_ENDPOINT
    cd sparql-proxy/NEW_ENDPOINT
    ln -s ../common/docker-compose.yml
    ```

    Then create `.env` and add environment variables used in `docker-compose.yml`.

    ```
    ENDPOINT_NAME=NEW_ENDPOINT
    HOST_PORT=10***
    LOGS_DIR=/data/rdfportal/logs/sparql-proxy
    ```

   Finally, run the `configure` script to update the `Makefile` created in the [setup section](#setup).
