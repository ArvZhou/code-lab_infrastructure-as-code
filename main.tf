terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

provider "null" {}

variable "ssh_password" {
  description = "SSH password for remote connection"
  type        = string
  sensitive   = true
}

resource "null_resource" "install_docker_k3s" {
  connection {
    type     = "ssh"
    host     = "114.218.145.161"
    user     = "arvin"
    password = var.ssh_password
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
      "  curl -sfL https://get.k3s.io | sh -",
      "else",
      "  echo 'k3s 已安装，跳过安装'",
      "fi",

      "# 等待k3s服务启动",
      "sleep 10",

      "# 配置kubectl环境变量",
      "if [ ! -f $HOME/.kube/config ]; then",
      "  mkdir -p $HOME/.kube",
      "  sudo cp /etc/rancher/k3s/k3s.yaml $HOME/.kube/config",
      "  sudo chown $(id -u):$(id -g) $HOME/.kube/config",
      "else",
      "  echo 'kubectl配置已存在，跳过'",
      "fi",
    ]
  }
}
