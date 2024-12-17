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
    local_id bigint not null,
    guid uuid not null,
    unique(branch_id, local_id)
);

alter table items
    add constraint items_branch_id_fk foreign key (branch_id) references branches (id);

create table item_states (
    id bigserial primary key,
    item_id bigint not null,
    fetched_at timestamptz not null default now(),
    deleted_at timestamptz,
    modified_at timestamptz not null,
    name text not null,
    price integer not null
);

create index item_states_latest_idx on item_states (item_id, fetched_at);

alter table item_states
    add constraint item_states_item_id_fk foreign key (item_id) references items (id);

create table categories (
    id bigserial primary key,
    branch_id bigint not null,
    local_id bigint not null,
    guid uuid not null,
    unique(branch_id, local_id)
);

alter table categories
    add constraint categories_branch_id_fk foreign key (branch_id) references branches (id);

create table category_states (
    id bigserial primary key,
    category_id bigint not null,
    fetched_at timestamptz not null default now(),
    deleted_at timestamptz,
    modified_at timestamptz not null,
    name text not null
);

create index category_states_latest_idx on category_states (category_id, fetched_at);

alter table category_states
    add constraint category_states_category_id_fk foreign key (category_id) references categories (id);

create table item_categories (
    id bigserial primary key,
    branch_id bigint not null,
    local_id bigint not null,
    guid uuid not null,
    unique(branch_id, local_id)
);

alter table item_categories
    add constraint item_categories_branch_id_fk foreign key (branch_id) references branches (id);

create table item_category_states (
    id bigserial primary key,
    item_category_id bigint not null,
    fetched_at timestamptz not null default now(),
    deleted_at timestamptz,
    modified_at timestamptz not null,
    item_id bigint not null,
    category_id bigint not null
);

alter table item_category_states
    add constraint item_category_states_item_category_id_fk foreign key (item_category_id) references item_categories (id),
    add constraint item_category_states_item_id_fk foreign key (item_id) references items (id),
    add constraint item_category_states_category_id_fk foreign key (category_id) references categories (id);

create index item_category_states_latest_idx on item_category_states (item_category_id, fetched_at);

create table buyers (
    id bigserial primary key,
    branch_id bigint not null,
    local_id bigint not null,
    guid uuid not null,
    unique(branch_id, local_id)
);

alter table buyers
    add constraint buyers_branch_id_fk foreign key (branch_id) references branches (id);

create table buyer_states (
    id bigserial primary key,
    buyer_id bigint not null,
    fetched_at timestamptz not null default now(),
    deleted_at timestamptz,
    modified_at timestamptz not null not null
);

alter table buyer_states
    add constraint buyer_states_buyer_id_fk foreign key (buyer_id) references buyers (id);

create index buyer_states_latest_idx on buyer_states (buyer_id, fetched_at);

create table sales (
    id bigserial primary key,
    branch_id bigint not null,
    local_id bigint not null,
    guid uuid not null,
    unique(branch_id, local_id)
);

alter table sales
    add constraint sales_branch_id_fk foreign key (branch_id) references branches (id);

create table sale_states (
    id bigserial primary key,
    sale_id bigint not null,
    fetched_at timestamptz not null default now(),
    deleted_at timestamptz,
    modified_at timestamptz not null,
    created_at timestamptz not null,
    finalized_at timestamptz,
    buyer_id bigint not null,
    total integer not null
);

create index sale_states_latest_idx on sale_states (sale_id, fetched_at);

alter table sale_states
    add constraint sale_states_sale_id_fk foreign key (sale_id) references sales (id),
    add constraint sale_states_buyer_id_fk foreign key (buyer_id) references buyers (id);

create table sale_items (
    id bigserial primary key,
    branch_id bigint not null,
    local_id bigint not null,
    guid uuid not null,
    unique(branch_id, local_id)
);

alter table sale_items
    add constraint sale_items_branch_id_fk foreign key (branch_id) references branches (id);

create table sale_item_states (
    id bigserial primary key,
    sale_item_id bigint not null,
    fetched_at timestamptz not null default now(),
    deleted_at timestamptz,
    modified_at timestamptz not null,
    sale_id bigint not null,
    item_id bigint not null,
    count integer not null,
    price integer not null
);

create index sale_item_states_latest_idx on sale_item_states (sale_item_id, fetched_at);

alter table sale_item_states
    add constraint sale_item_states_sale_item_id_fk foreign key (sale_item_id) references sale_items (id),
    add constraint sale_item_states_sale_id_fk foreign key (sale_id) references sales (id),
    add constraint sale_item_states_item_id_fk foreign key (item_id) references items (id);
