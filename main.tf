terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

provider "null" {}

// 变量定义已移至 variables.tf
# variable "ssh_password" {
#   description = "SSH password for remote connection"
#   type        = string
#   sensitive   = true
# }

// variable "mysql_root_password" {
//   description = "MySQL root password"
//   type        = string
//   sensitive   = true
// }

resource "null_resource" "install_docker_k3s" {
  connection {
    type     = "ssh"
    host     = "114.218.145.161"
    user     = "arvin"
    password = var.ssh_password
  }
#   provisioner "file" {
#     source      = "${path.module}/sudoers-arvin-nopasswd"
#     destination = "/etc/sudoers.d/arvin-nopasswd"
#   }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod 440 /etc/sudoers.d/arvin-nopasswd"
    ]
  }

  provisioner "file" {
    source      = "${path.module}/k3s.sh"
    destination = "/tmp/k3s_install/k3s.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "if ! command -v docker >/dev/null 2>&1; then",
      "  sudo apt-get update",
      "  sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common",
      "  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "  sudo add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable'",
      "  sudo apt-get update",
      "  sudo apt-get install -y docker-ce",
      "  sudo systemctl start docker",
      "  sudo systemctl enable docker",
      "else",
      "  echo 'Docker 已安装，跳过安装'",
      "fi",

      "if ! command -v k3s >/dev/null 2>&1; then",
      "  sh /tmp/k3s_install/k3s.sh",
      "else",
      "  echo 'k3s 已安装，跳过安装'",
      "fi",

      "echo '等待k3s服务启动'",
      "sleep 10"
    ]
  }
}

resource "kubernetes_namespace" "app" {
  metadata {
    name = "app"
  }
}

resource "kubernetes_deployment" "mysql" {
  metadata {
    name      = "mysql"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "mysql"
      }
    }

    template {
      metadata {
        labels = {
          app = "mysql"
        }
      }

      spec {
        container {
          name  = "mysql"
          image = "mysql:latest"

          env {
            name  = "MYSQL_ROOT_PASSWORD"
            value = var.mysql_root_password
          }

          port {
            container_port = 3306
          }

          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "mysql" {
  metadata {
    name      = "mysql"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  spec {
    selector = {
      app = "mysql"
    }

    port {
      port        = 3306
      target_port = 3306
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_deployment" "redis" {
  metadata {
    name      = "redis"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "redis"
      }
    }

    template {
      metadata {
        labels = {
          app = "redis"
        }
      }

      spec {
        container {
          name  = "redis"
          image = "redis:latest"

          port {
            container_port = 6379
          }

          resources {
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "redis" {
  metadata {
    name      = "redis"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  spec {
    selector = {
      app = "redis"
    }

    port {
      port        = 6379
      target_port = 6379
    }

    type = "ClusterIP"
  }
}
