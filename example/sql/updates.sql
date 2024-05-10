--name: UpdateNameCustomerById :exec
update customers set name = :name where id = :whereId;
