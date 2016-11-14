# terraform-redis-clustering
A quick example for setting up Rabbit with terraform.

## Terraform

Check everything is oke.

`terraform plan`

Apply changes.

`terraform apply`

# Setup Includes

* 1 rabbit server
* 1 vhost
* 1 exchange
* 1 queue

> *Note*: I found an issue with the terraform provider around arguments they are all passed as string so things like x-message-ttl which needs to be an integer terraform is passing as a string so it fails.