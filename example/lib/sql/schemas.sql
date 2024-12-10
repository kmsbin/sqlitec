create table orders (
    id integer primary key autoincrement,
    total decimal(5, 10) not null default 0,
    customer_id int,
    customer_name varchar,
    customer_status varchar not null default 'Hello there''s',
    date timestamp not null,
    dated timestamp null
);

create table customers (
    id integer primary key autoincrement,
    name varchar not null default null,
    status varchar not null default '',
    updated_at timestamp not null default current_date
);

--name: getCustumerByNameAndStatus :one
select * from customers where name = ? and status = :status;

--name: insertCustumer :exec
insert into customers(name, status) values (?, ?);

create table payments (
    id int primary key,
    customer_id int not null,
    orders_id int not null,
    amount real not null
);
