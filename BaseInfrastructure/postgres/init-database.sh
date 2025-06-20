#!/bin/bash
set -e
# crrate postgres database stucture and users
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE USER keycloak WITH ENCRYPTED PASSWORD '${POSTGRES_KEYCLOAK_PASSWORD}';
    CREATE DATABASE keycloak OWNER keycloak;
    GRANT ALL PRIVILEGES ON DATABASE keycloak TO keycloak;
    CREATE USER boundary_service WITH ENCRYPTED PASSWORD '${POSTGRES_BOUNDARY_SERVICE_PASSWORD}';
    CREATE DATABASE boundaries OWNER boundary_service;
    GRANT ALL PRIVILEGES ON DATABASE boundaries TO boundary_service;
    CREATE USER drive WITH ENCRYPTED PASSWORD '${POSTGRES_DRIVE_PASSWORD}';
    CREATE DATABASE esdlrepo OWNER drive;
    GRANT ALL PRIVILEGES ON DATABASE esdlrepo TO drive;
    ALTER USER drive CREATEDB;
EOSQL
# source boundary_services
psql --username "$POSTGRES_USER" --dbname boundaries -c "CREATE EXTENSION postgis;"
psql --username "$POSTGRES_USER" --dbname boundaries -c "CREATE EXTENSION postgis_topology;"

psql --username "$POSTGRES_USER" --dbname boundaries -f /data/boundaries/bu_wk_gm_es_pv_la.sql

shp2pgsql -s 4326 /data/boundaries/buurt_2019_wgs.shp public.buurt_2019_wgs | psql --username boundary_service --dbname boundaries
shp2pgsql -s 4326 /data/boundaries/wijk_2019_wgs.shp public.wijk_2019_wgs | psql --username boundary_service --dbname boundaries
shp2pgsql -s 4326 /data/boundaries/gem_2019_wgs.shp public.gem_2019_wgs | psql --username boundary_service --dbname boundaries
shp2pgsql -s 4326 /data/boundaries/res_2019_wgs.shp public.res_2019_wgs | psql --username boundary_service --dbname boundaries
shp2pgsql -s 4326 /data/boundaries/prov_2019_wgs.shp public.prov_2019_wgs | psql --username boundary_service --dbname boundaries
shp2pgsql -s 4326 /data/boundaries/land_2019_wgs.shp public.land_2019_wgs | psql --username boundary_service --dbname boundaries
# source keycloak with initial install and esdi realm (notice this sql injects password from the tutorial so env is overidden)
psql --username "$POSTGRES_USER" --dbname keycloak -f ../keycloak/keycloak.postgres.sql
