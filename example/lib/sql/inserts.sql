
-- name: insertCustomer :exec
insert into customers values(?, ?, ?);

--name: insertOrder :exec
insert into orders values (?, ?, ?, ?, ?);
