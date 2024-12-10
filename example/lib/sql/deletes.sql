-- name: deleteCustomerByName :exec
delete from customers where name = ? or name = :name;


with custumers_without_payments as (
    select c.id
    from customers c
    left join payments p on c.id = p.customer_id
    where p.customer_id is null
)
-- name: deleteCustomersWithoutPayments :exec
delete from customers where id in (select id from custumers_without_payments);

