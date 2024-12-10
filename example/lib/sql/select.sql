-- name: getCustomersById :many
select * from customers where customers.id = ?;

-- name: getCustomerById :one
select * from customers where customers.id = ?;

-- name: getCustomersIdWhereStatusIs :many
select id from customers where status = :status;

