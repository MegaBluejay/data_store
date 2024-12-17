\c :"branch"

create temp table basic_cats (
  num int,
  name text
);

\copy basic_cats(num, name) from 'lab1/basic_cats.csv' delimiter ',' csv

create temp table temp_items (
  cat_num int,
  name text
);

\copy temp_items(cat_num, name) from 'lab1/items.csv' delimiter ',' csv

insert into items (name, price)
select name, ceil(random() * 100)
from temp_items
, (
  select random()
  from generate_series(0,1)
) ord(n)
order by ord.n
limit 25;

insert into categories (name)
select name
from basic_cats
order by random();

insert into item_categories (item_id, category_id)
select items.id, categories.id
from items
join temp_items on items.name = temp_items.name
join basic_cats on temp_items.cat_num = basic_cats.num
join categories on basic_cats.name = categories.name;

insert into categories (name)
select format('Promo %s', n::text)
from generate_series(1, 15) as promos(n)
order by random();

insert into item_categories (item_id, category_id)
select item_ids.id, 26 - promos.n
from generate_series(1, 14) as promos(n)
, (
  select id
  from items
  order by random()
  limit 2
) item_ids;

insert into buyers
select
from generate_series(1, 25);

insert into sales (buyer_id)
select ceil(random() * 25)
from generate_series(1, 25);

insert into sale_items (sale_id, item_id, price, count)
select ceil(random() * 25), ceil(random() * 25), ceil(random() * 100), ceil(random() * 100)
from generate_series(1, 50);

update sales set finalized_at = now()
where
  total > 0
  and
  random() > 0.5;
