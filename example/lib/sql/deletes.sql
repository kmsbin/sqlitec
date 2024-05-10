-- name: DeleteCustomerByName :exec
delete from customers where name = ? or name = :name;
