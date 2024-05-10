
-- name: InsertCustomer :exec
insert into customers values(?, ?, ?);

--name: InsertOrder :exec
insert into orders values (?, ?, ?, ?, ?);
