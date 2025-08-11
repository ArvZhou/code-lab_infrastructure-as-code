#!/bin/bash

mirrors=(
  "https://docker.m.daocloud.io"
  "https://docker.1ms.run"
  "https://ccr.ccs.tencentyun.com"
  "https://hub.xdark.top"
  "https://hub.fast360.xyz"
  "https://docker-0.unsee.tech"
  "https://docker.xuanyuan.me"
  "https://docker.tbedu.top"
  "https://docker.hlmirror.com"
  "https://doublezonline.cloud"
  "https://docker.melikeme.cn"
  "https://image.cloudlayer.icu"
  "https://dislabaiot.xyz"
  "https://freeno.xyz"
  "https://docker.kejilion.pro"
)

echo "开始测试国内镜像加速地址连通性..."

for url in "${mirrors[@]}"; do
  echo -n "测试 $url ... "
  status_code=$(curl -o /dev/null -s -w "%{http_code}" "$url/v2/")
  if [[ "$status_code" == "200" || "$status_code" == "401" ]]; then
    echo "可用 (HTTP $status_code)"
  else
    echo "不可用或访问异常 (HTTP $status_code)"
  fi
done

echo "测试完成。"