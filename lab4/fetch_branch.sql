\c storage

insert into branches (name)
values (:'branch')
on conflict do nothing;

create extension if not exists postgres_fdw;

create server if not exists :"branch"
foreign data wrapper postgres_fdw
options (
    dbname :'branch'
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


create or replace function fetch_new(branch public.branches)
returns void as $func$
begin
    execute format(
        $sql$
        insert into public.items (
            branch_id,
            fetched_at,
            local_id,
            guid,
            modified_at,
            name,
            price
        )
        select
            $1,
            now(),
            i.id,
            guid,
            modified_at,
            name,
            price
        from %1$I.items i
        where
            case
            when $2 is null
            then true
            else modified_at > $2
            end;
        
        insert into public.categories (
            branch_id,
            fetched_at,
            local_id,
            guid,
            modified_at,
            name
        )
        select
            $1,
            now(),
            c.id,
            guid,
            modified_at,
            name
        from %1$I.categories c
        where
            case
            when $2 is null
            then true
            else modified_at > $2
            end;

        insert into public.item_categories (
            branch_id,
            fetched_at,
            local_id,
            guid,
            modified_at,
            item_id,
            category_id
        )
        select
            $1,
            now(),
            ic.id,
            guid,
            modified_at,
            li.id,
            lc.id
        from %1$I.item_categories ic
        , lateral (
            select id
            from public.items
            where
                branch_id = $1
                and
                local_id = ic.item_id
            order by id desc
            limit 1
        ) li
        , lateral (
            select id
            from public.categories
            where
                branch_id = $1
                and
                local_id = ic.category_id
            order by id desc
            limit 1
        ) lc
        where
            case
            when $2 is null
            then true
            else modified_at > $2
            end;
        
        insert into public.buyers (
            branch_id,
            fetched_at,
            local_id,
            guid,
            modified_at
        )
        select
            $1,
            now(),
            id,
            guid,
            modified_at
        from %1$I.buyers
        where
            case
            when $2 is null
            then true
            else modified_at > $2
            end;
        
        insert into public.sales (
            branch_id,
            fetched_at,
            local_id,
            guid,
            modified_at,
            created_at,
            finalized_at,
            buyer_id,
            total
        )
        select
            $1,
            now(),
            s.id,
            guid,
            modified_at,
            created_at,
            finalized_at,
            lb.id,
            total
        from %1$I.sales s
        , lateral (
            select id
            from public.buyers
            where
                branch_id = $1
                and
                local_id = s.buyer_id
            order by id desc
            limit 1
        ) lb
        where
            case
            when $2 is null
            then true
            else modified_at > $2
            end;
        
        insert into public.sale_items (
            branch_id,
            fetched_at,
            local_id,
            guid,
            modified_at,
            sale_id,
            item_id,
            count,
            price
        )
        select
            $1,
            now(),
            si.id,
            guid,
            modified_at,
            ls.id,
            li.id,
            count,
            price
        from %1$I.sale_items si
        , lateral (
            select id
            from public.sales
            where
                branch_id = $1
                and
                local_id = si.sale_id
            order by id desc
            limit 1
        ) ls, lateral (
            select id
            from public.items
            where
                branch_id = $1
                and
                local_id = si.item_id
            order by id desc
            limit 1
        ) li
        where
            case
            when $2 is null
            then true
            else modified_at > $2
            end;
        $sql$,
        branch.name
    ) using branch.id, branch.last_fetched_at;
    update public.branches
    set last_fetched_at = now()
    where id = branch.id;
end;
$func$ language 'plpgsql';

select fetch_new(branches) from branches where name = :'branch';
