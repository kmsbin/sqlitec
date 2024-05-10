-- name: GetCustomersById :many
select * from customers where customers.id = ?;

-- name: GetCustomerById :one
select * from customers where customers.id = ?;

-- name: GetCustomersIdWhereStatusIs :many
select id from customers where status = :status;

