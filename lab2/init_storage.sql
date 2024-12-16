create database storage;
\c storage

create table branches (
    id bigserial primary key,
    name text not null unique,
    last_fetched_at timestamptz
);

create table items (
    id bigserial primary key,
    branch_id bigint not null,
    fetched_at timestamptz not null,
    local_id bigint not null,
    guid uuid not null,
    modified_at timestamptz not null,
    name text not null,
    price integer not null
);

create index items_last_version_idx on items (branch_id, local_id, id);

alter table items
    add constraint items_branch_id_fk foreign key (branch_id) references branches (id);

create table categories (
    id bigserial primary key,
    branch_id bigint not null,
    fetched_at timestamptz not null,
    local_id bigint not null,
    guid uuid not null,
    modified_at timestamptz not null,
    name text not null
);

create index categories_last_version_idx on categories (branch_id, local_id, id);

alter table categories
    add constraint categories_branch_id_fk foreign key (branch_id) references branches (id);

create table item_categories (
    id bigserial primary key,
    branch_id bigint not null,
    fetched_at timestamptz not null,
    local_id bigint not null,
    guid uuid not null,
    modified_at timestamptz not null,
    item_id bigint not null,
    category_id bigint not null
);

create index item_categories_last_version_idx on item_categories (branch_id, local_id, id);

alter table item_categories
    add constraint item_categories_branch_id_fk foreign key (branch_id) references branches (id),
    add constraint item_categories_item_id_fk foreign key (item_id) references items (id),
    add constraint item_categories_category_id_fk foreign key (category_id) references categories (id);

create table buyers (
    id bigserial primary key,
    branch_id bigint not null,
    fetched_at timestamptz not null,
    local_id bigint not null,
    guid uuid not null,
    modified_at timestamptz not null
);

create index buyers_last_version_idx on buyers (branch_id, local_id, id);

alter table buyers
    add constraint buyers_branch_id_fk foreign key (branch_id) references branches (id);

create table sales (
    id bigserial primary key,
    branch_id bigint not null,
    fetched_at timestamptz not null,
    local_id bigint not null,
    guid uuid not null,
    modified_at timestamptz not null,
    created_at timestamptz not null,
    finalized_at timestamptz,
    buyer_id bigint not null,
    total integer not null
);

create index sales_last_version_idx on sales (branch_id, local_id, id);

alter table sales
    add constraint sales_branch_id_fk foreign key (branch_id) references branches (id),
    add constraint sales_buyer_id_id_fk foreign key (buyer_id) references buyers (id);

create table sale_items (
    id bigserial primary key,
    branch_id bigint not null,
    fetched_at timestamptz not null,
    local_id bigint not null,
    guid uuid not null,
    modified_at timestamptz not null,
    sale_id bigint not null,
    item_id bigint not null,
    count integer not null,
    price integer not null
);

create index sale_items_last_version_idx on sale_items (branch_id, local_id, id);

alter table sale_items
    add constraint sale_items_branch_id_fk foreign key (branch_id) references branches (id),
    add constraint sale_items_sale_id_fk foreign key (sale_id) references sales (id),
    add constraint sale_items_item_id_fk foreign key (item_id) references items (id);
