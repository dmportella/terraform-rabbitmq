# Configure the Docker provider
provider "docker" {
	host = "unix:///var/run/docker.sock"
}


resource "docker_image" "rabbitmq" {
	name = "rabbitmq:3.6.5-management"
}

resource "docker_container" "rabbitmq" {
	image = "${docker_image.rabbitmq.latest}"
	name = "rabbitmq"

	env = ["RABBITMQ_DEFAULT_USER=guest", "RABBITMQ_DEFAULT_PASS=guest"]

    ports {
        internal = 15672
        external = 15672
        ip = "172.17.0.1"
    }

	restart = "always"
}

resource "null_resource" "wait" {
	depends_on = ["docker_container.rabbitmq"]

	provisioner "local-exec" {
		command = "echo 'Sleeping for 5...' && sleep 5"
	}
}


# Configure the RabbitMQ provider
provider "rabbitmq" {
	endpoint = "http://172.17.0.1:15672"
	username = "guest"
	password = "guest"
}

# Create a virtual host
resource "rabbitmq_vhost" "vhost_1" {
	depends_on = ["null_resource.wait"]

	name = "vhost_1"
}

resource "rabbitmq_permissions" "guest" {
	depends_on = ["null_resource.wait"]

	user = "guest"
	vhost = "${rabbitmq_vhost.vhost_1.name}"
	permissions {
		configure = ".*"
		write = ".*"
		read = ".*"
	}
}

resource "rabbitmq_exchange" "riverstyx" {
	depends_on = ["null_resource.wait"]
	
	name = "riverstyx"
	vhost = "${rabbitmq_permissions.guest.vhost}"
	settings {
		type = "fanout"
		durable = false
		auto_delete = true
	}
}

resource "rabbitmq_queue" "debug" {
	depends_on = ["null_resource.wait"]
	
	name = "debug-queue"
	vhost = "${rabbitmq_permissions.guest.vhost}"
	settings {
		durable = false
		auto_delete = true
		arguments = {
			message-ttl = 60000
		}
	}
}

resource "rabbitmq_binding" "binding" {
	depends_on = ["null_resource.wait"]
	
	source = "${rabbitmq_exchange.riverstyx.name}"
	vhost = "${rabbitmq_permissions.guest.vhost}"
	destination = "${rabbitmq_queue.debug.name}"
	destination_type = "queue"
	routing_key = "*"
	properties_key = "%23"
}