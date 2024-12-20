\c storage

insert into branches (name)
values (:'branch')
on conflict do nothing;

create extension if not exists postgres_fdw;
create extension if not exists dblink;

create server if not exists :"branch"
foreign data wrapper postgres_fdw
options (
    dbname :'branch',
    options '-c session_replication_role=replica'
);

create user mapping if not exists
for postgres
server :branch
options (
    user 'postgres'
);

drop schema if exists :"branch" cascade;
create schema :"branch";

import foreign schema public
from server :"branch"
into :"branch";
