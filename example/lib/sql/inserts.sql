
-- name: insertCustomer :exec
insert into customers values(?, ?, ?);

--name: insertOrder :exec
insert into orders values (?, ?, ?, ?, ?);

--name: updateOrdersTotalByCustomerId :exec
update orders
set total = :total
where customer_id = ?