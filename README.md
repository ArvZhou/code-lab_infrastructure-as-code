# Infrastructure as Code with Terraform

## 项目简介

本项目使用Terraform自动化在Ubuntu服务器上安装Docker和k3s（轻量级Kubernetes），并通过Terraform的Kubernetes Provider管理MySQL和Redis服务。

## 目录结构

- `main.tf`：负责远程安装Docker和k3s集群环境和使用Kubernetes Provider管理MySQL和Redis的Kubernetes资源。
- `.github/workflows/terraform-deploy.yml`：GitHub Actions工作流，支持手动触发，分步执行Terraform部署。

## 使用说明

### 1. 配置GitHub Secrets

在GitHub仓库的Settings > Secrets and variables > Actions中添加以下Secrets：

- `SSH_PASSWORD`：远程Ubuntu服务器SSH密码。
- `MYSQL_ROOT_PASSWORD`：MySQL数据库root用户密码。

### 2. 触发部署

在GitHub Actions页面手动触发`Terraform Deploy`工作流，依次完成Docker和k3s安装，以及MySQL和Redis的部署。

### 3. 本地运行（可选）

确保本地安装Terraform，并配置好SSH访问远程服务器。

```bash
export TF_VAR_ssh_password="your_ssh_password"
export TF_VAR_mysql_root_password="your_mysql_password"
terraform init
terraform apply -target=null_resource.install_docker_k3s
terraform apply
```

### 4. 本地访问集群中的MySQL数据库

1. 确保本地已安装并配置好`kubectl`，并能访问k3s集群。

2. 使用`kubectl port-forward`命令将本地端口转发到MySQL服务：

```bash
kubectl port-forward svc/mysql 3306:3306 -n app
```

3. 在本地通过`localhost:3306`连接MySQL，使用你设置的`mysql_root_password`进行登录。

4. 访问示例（使用MySQL客户端）：

```bash
mysql -h 127.0.0.1 -P 3306 -u root -p
```

## 国内镜像加速

为了加快镜像拉取速度，推荐使用以下国内镜像加速地址：

- https://docker.m.daocloud.io

### 在 k3s 中配置镜像加速

k3s 推荐使用 `registries.yaml` 文件配置镜像加速，配置文件路径为 `/etc/rancher/k3s/registries.yaml`。

示例配置内容：

```yaml
mirrors:
  docker.io:
    endpoint:
      - "https://docker.m.daocloud.io"
configs:
  "https://docker.m.daocloud.io":
    tls:
      insecure_skip_verify: false
```

配置完成后，重启 k3s 服务使配置生效：

```bash
sudo systemctl restart k3s
```

这样 k3s 内置的 containerd 会优先使用配置的国内镜像加速地址，提高镜像拉取速度。

---

## 无密码 sudo 配置（用户名暂且叫 arvin）

为了让用户 `arvin` 能够无密码执行部分管理命令，需要在远程服务器的 `/etc/sudoers.d/arvin-nopasswd` 文件中添加以下内容：

```
arvin ALL=(ALL) NOPASSWD: /usr/bin/*
```

该配置允许 `arvin` 用户无密码执行 `apt-get` 和 `systemctl` 命令，方便自动化脚本运行。

请确保该文件权限设置为 440，且文件放置在 `/etc/sudoers.d/` 目录下。

示例文件已包含在项目中，Terraform 脚本会自动上传并应用该配置。

## 注意事项

- k3s为轻量级Kubernetes，适合学习和小型生产环境。
- Terraform管理的是基础设施和Kubernetes资源，具体服务配置请根据需求调整。
- 确保远程服务器开启SSH服务并允许Terraform连接。

## 参考资料

- [Terraform官方文档](https://www.terraform.io/docs)
- [k3s官方文档](https://k3s.io/)
- [Kubernetes Provider for Terraform](https://registry.terraform.io/providers/hashicorp/kubernetes/latest)

---

## 友好提示：配置kubectl访问k3s集群

确保本地安装并配置好`kubectl`访问k3s集群，具体步骤如下：

1. **安装kubectl**

   根据操作系统安装kubectl，官方文档：https://kubernetes.io/docs/tasks/tools/

   例如macOS用Homebrew：`brew install kubectl`，Windows用chocolatey：`choco install kubernetes-cli`

2. **获取k3s集群的kubeconfig文件**

   远程登录你的k3s服务器，执行：

   ```bash
   sudo cat /etc/rancher/k3s/k3s.yaml
   ```

   将内容复制到本地的`~/.kube/config`文件中（如果没有该文件，需新建）

3. **修改kubeconfig中的服务器地址**

   默认k3s的kubeconfig中服务器地址是`https://127.0.0.1:6443`，需要改成你的k3s服务器公网IP或内网IP，例如：

   ```yaml
   server: https://114.218.145.161:6443
   ```

4. **测试连接**

   在本地终端执行：

   ```bash
   kubectl get nodes
   ```

   如果能看到节点列表，说明配置成功。

如有问题，欢迎反馈。
