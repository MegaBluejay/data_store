\c storage

create function restore(branch public.branches)
returns void as $func$
begin
    execute format(
        $sql$
        insert into %1$I.items (
            id,
            guid,
            modified_at,
            name,
            price
        )
        select
            i.local_id,
            i.guid,
            li.modified_at,
            li.name,
            li.price
        from public.items i
        join (
            select distinct on (item_id)
                *
            from public.item_states
            order by item_id, fetched_at desc
        ) li on li.item_id = i.id
        where
            i.branch_id = $1
            and
            li.deleted_at is null
        order by i.local_id;

        insert into %1$I.categories (
            id,
            guid,
            modified_at,
            name
        )
        select
            c.local_id,
            c.guid,
            lc.modified_at,
            lc.name
        from public.categories c
        join (
            select distinct on (category_id)
                *
            from public.category_states
            order by category_id, fetched_at desc
        ) lc on lc.category_id = c.id
        where
            c.branch_id = $1
            and
            lc.deleted_at is null
        order by c.local_id;

        insert into %1$I.item_categories (
            id,
            guid,
            modified_at,
            item_id,
            category_id
        )
        select
            ic.local_id,
            ic.guid,
            lic.modified_at,
            i.local_id,
            c.local_id
        from public.item_categories ic
        join (
            select distinct on (item_category_id)
                *
            from public.item_category_states
            order by item_category_id, fetched_at desc
        ) lic on lic.item_category_id = ic.id
        join public.items i on i.id = lic.item_id
        join public.categories c on c.id = lic.category_id
        where
            ic.branch_id = $1
            and
            lic.deleted_at is null
        order by ic.local_id;

        insert into %1$I.buyers (
            id,
            guid,
            modified_at
        )
        select
            b.local_id,
            b.guid,
            lb.modified_at
        from public.buyers b
        join (
            select distinct on (buyer_id)
                *
            from public.buyer_states
            order by buyer_id, fetched_at desc
        ) lb on lb.buyer_id = b.id
        where
            b.branch_id = $1
            and
            lb.deleted_at is null
        order by b.local_id;

        insert into %1$I.sales (
            id,
            guid,
            modified_at,
            created_at,
            finalized_at,
            buyer_id,
            total
        )
        select
            s.local_id,
            s.guid,
            ls.modified_at,
            ls.created_at,
            ls.finalized_at,
            b.local_id,
            ls.total
        from public.sales s
        join (
            select distinct on (sale_id)
                *
            from public.sale_states
            order by sale_id, fetched_at desc
        ) ls on ls.sale_id = s.id
        join public.buyers b on b.id = ls.buyer_id
        where
            s.branch_id = $1
            and
            ls.deleted_at is null
        order by s.local_id;

        insert into %1$I.sale_items (
            id,
            guid,
            modified_at,
            sale_id,
            item_id,
            count,
            price
        )
        select
            si.local_id,
            si.guid,
            lsi.modified_at,
            s.local_id,
            i.local_id,
            lsi.count,
            lsi.price
        from public.sale_items si
        join (
            select distinct on (sale_item_id)
                *
            from public.sale_item_states
            order by sale_item_id, fetched_at desc
        ) lsi on lsi.sale_item_id = si.id
        join public.sales s on s.id = lsi.sale_id
        join public.items i on i.id = lsi.item_id
        where
            si.branch_id = $1
            and
            lsi.deleted_at is null
        order by si.local_id;
        $sql$,
        branch.name
    ) using branch.id;

    perform dblink_connect(branch.name, branch.name);

    perform from dblink(
        branch.name,
        format(
            $sql$
            select setval('public.items_id_seq', %L)
            $sql$,
            (select max(local_id) from public.items where branch_id = branch.id)
        )
    ) x(setval bigint);

    perform from dblink(
        branch.name,
        format(
            $sql$
            select setval('public.categories_id_seq', %L)
            $sql$,
            (select max(local_id) from public.categories where branch_id = branch.id)
        )
    ) x(setval bigint);

    perform from dblink(
        branch.name,
        format(
            $sql$
            select setval('public.item_categories_id_seq', %L)
            $sql$,
            (select max(local_id) from public.item_categories where branch_id = branch.id)
        )
    ) x(setval bigint);

    perform from dblink(
        branch.name,
        format(
            $sql$
            select setval('public.buyers_id_seq', %L)
            $sql$,
            (select max(local_id) from public.buyers where branch_id = branch.id)
        )
    ) x(setval bigint);

    perform from dblink(
        branch.name,
        format(
            $sql$
            select setval('public.sales_id_seq', %L)
            $sql$,
            (select max(local_id) from public.sales where branch_id = branch.id)
        )
    ) x(setval bigint);

    perform from dblink(
        branch.name,
        format(
            $sql$
            select setval('public.sale_items_id_seq', %L)
            $sql$,
            (select max(local_id) from public.sale_items where branch_id = branch.id)
        )
    ) x(setval bigint);
end;
$func$ language 'plpgsql';
