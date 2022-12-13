terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone      = "ru-central1-a"
}

resource "yandex_compute_instance" "vm-1" {
  name = "terraform1"

  resources {
    cores  = 2
    memory = 2
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update && sudo apt-get install -y nginx && sudo apt-get install -y docker.io && sudo docker pull milanfun/yccloud && sudo docker run -dit --name app -p 9090:9090 milanfun/yccloud"
    ] 
    connection {
      type = "ssh"
      user = var.yc_user
      private_key = file(var.ssh_key)
      host = self.network_interface[0].nat_ip_address
    }
  }

  boot_disk {
    initialize_params {
      image_id = "fd8kdq6d0p8sij7h5qe3"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("${var.ssh_key}.pub")}"
  }
}

resource "yandex_mdb_mysql_cluster" "my-mysql" {
  name                = "mysql"
  environment         = "PRESTABLE"
  network_id          = yandex_vpc_network.network-1.id
  version             = "8.0"
  deletion_protection = true

  resources {
    resource_preset_id = "s2.micro"
    disk_type_id       = "network-ssd"
    disk_size          = 20
  }

  access {
    web_sql   = true
    data_lens = true
  }

  host {
    zone      = "ru-central1-a"
    subnet_id = yandex_vpc_subnet.subnet-1.id
  }
}

resource "yandex_mdb_mysql_database" "users" {
  cluster_id = yandex_mdb_mysql_cluster.my-mysql.id
  name       = "users"
}

resource "yandex_mdb_mysql_user" "user1" {
  cluster_id = yandex_mdb_mysql_cluster.my-mysql.id
  name       = "user1"
  password   = "password"
  permission {
    database_name = yandex_mdb_mysql_database.users.name
    roles         = ["ALL"]
  }
}

resource "yandex_api_gateway" "api-gateway" {
  name        = "devops"
  description = "DevOps shlus"
  labels      = {
    label       = "label"
    empty-label = ""
  }
  spec = <<-EOT
  openapi: 3.0.1
  info:
    title: OpenAPI definition
    version: v0
  paths:
    "/user/add":
      post:
        tags:
        - user-rest-controller
        summary: Add user by its first name, last name, email and age
        operationId: addUser
        requestBody:
          content:
            application/json:
              schema:
                "$ref": "#/components/schemas/User"
          required: true
        responses:
          '200':
            description: Add new user was success
            content:
              application/json:
                schema:
                  "$ref": "#/components/schemas/User"
          '400':
            description: Invalid parameters or parameters is not present
        x-yc-apigateway-integration:
          type: http
          url: http://51.250.67.157:9090/user/add
          method: POST
    "/user/getuser/{id}":
      get:
        tags:
        - user-rest-controller
        summary: Get a user by its id
        operationId: getUserById
        parameters:
        - name: id
          in: path
          required: true
          schema:
            type: integer
            format: int32
        responses:
          '200':
            description: Add new user was success
            content:
              application/json:
                schema:
                  "$ref": "#/components/schemas/User"
          '400':
            description: Invalid parameters or parameters is not present
        x-yc-apigateway-integration:
          type: http
          url: http://51.250.67.157:9090/user/getuser/{id}
          method: GET
    "/user/all":
      get:
        tags:
        - user-rest-controller
        summary: Get all user in database
        operationId: getAllUsers
        responses:
          '200':
            description: Ok! All user exists
            content:
              application/json:
                schema:
                  "$ref": "#/components/schemas/User"
          '404':
            description: Table not found
        x-yc-apigateway-integration:
          type: http
          url: http://51.250.67.157:9090/user/all
          method: GET
    "/user/delete/{id}":
      delete:
        tags:
        - user-rest-controller
        summary: Delete user by its id
        operationId: deleteUser
        parameters:
        - name: id
          in: path
          required: true
          schema:
            type: integer
            format: int32
        responses:
          '200':
            description: Found the user
            content:
              application/json:
                schema:
                  "$ref": "#/components/schemas/User"
          '400':
            description: Invalid id supplied
          '404':
            description: User not found
        x-yc-apigateway-integration:
          type: http
          url: http://51.250.67.157:9090/user/delete/{id}
          method: GET
    "/user/addUser":
      get:
        tags:
        - user-rest-controller
        summary: Add user via UI page
        operationId: addUser_2
        responses:
          '200':
            description: Adding successful
            content:
              application/json:
                schema:
                  "$ref": "#/components/schemas/UserForm"
          '400':
            description: Error
        x-yc-apigateway-integration:
          type: http
          url: http://51.250.67.157:9090/user/addUser
          method: GET
      post:
        tags:
        - user-rest-controller
        summary: POST via UI users
        operationId: addUser_1
        requestBody:
          content:
            application/json:
              schema:
                "$ref": "#/components/schemas/UserForm"
        responses:
          '200':
            description: Success
            content:
              application/json:
                schema:
                  "$ref": "#/components/schemas/UserForm"
          '400':
            description: Error
        x-yc-apigateway-integration:
          type: http
          url: http://51.250.67.157:9090/user/addUser
          method: POST
    "/user/userList":
      get:
        tags:
        - user-rest-controller
        summary: Get UI page with user list
        operationId: userList
        responses:
          '200':
            description: Success
            content:
              application/json:
                schema:
                  "$ref": "#/components/schemas/User"
          '400':
            description: Error
        x-yc-apigateway-integration:
          type: http
          url: http://51.250.67.157:9090/user/userList
          method: GET
  components:
    schemas:
      User:
        type: object
        properties:
          id:
            type: integer
            format: int32
          firstName:
            type: string
          lastName:
            type: string
          email:
            type: string
          age:
            type: integer
            format: int32
      UserForm:
        type: object
        properties:
          firstName:
            type: string
          lastName:
            type: string
          email:
            type: string
          age:
            type: integer
            format: int32
  EOT
}

resource "yandex_vpc_security_group" "mysql-sg" {
  name       = "mysql-sg"
  network_id = yandex_vpc_network.network-1.id

  ingress {
    description    = "MySQL"
    port           = 3306
    protocol       = "TCP"
    v4_cidr_blocks = [ "0.0.0.0/0" ]
  }
}

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}