terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.21.0"
    }
  }
}

provider "docker" {}

# ============================================================
# Docker Network
# ============================================================

resource "docker_network" "todo_net" {
  name = "todo-net"
}

# ============================================================
# Docker Images
# ============================================================

# Redis
resource "docker_image" "redis" {
  name         = "redis:6-alpine"
  keep_locally = true
}

# Todo Service
resource "docker_image" "todo" {
  name         = "natawut/todo-service:release-3"
  keep_locally = true
}

# Todo Notification Service
resource "docker_image" "todo_notification" {
  name         = "activity03-todo-notification-service:latest"
  keep_locally = true
}

# ============================================================
# Redis Container
# ============================================================

resource "docker_container" "redis" {
  name  = "redis"
  image = docker_image.redis.image_id

  networks_advanced {
    name = docker_network.todo_net.name
  }

  ports {
    internal = 6379
    external = 6379
  }
}

# ============================================================
# Todo Notification Service
# ============================================================

resource "docker_container" "todo_notification" {
  name  = "todo-notification-service"
  image = docker_image.todo_notification.image_id

  networks_advanced {
    name = docker_network.todo_net.name
  }

  ports {
    internal = 9000
    external = 9000
  }
}

# ============================================================
# Todo Service
# ============================================================

resource "docker_container" "todo" {
  name  = "todo-service"
  image = docker_image.todo.image_id

  networks_advanced {
    name = docker_network.todo_net.name
  }

  env = [
    "REDIS_HOST=redis",
    "NOTIFICATION_HOST=todo-notification-service",
    "NOTIFICATION_PORT=9000"
  ]

  ports {
    internal = 8000
    external = 8000
  }

  depends_on = [
    docker_container.redis,
    docker_container.todo_notification
  ]
}
