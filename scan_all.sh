#!/bin/bash

# 设置默认参数
ports="1-65535"
rate=1000
eth=""
fastScan=0
ipFile=""

# 解析命令行参数
while getopts ":p:rate:e:Ff:" opt; do
  case ${opt} in
    p ) ports=$OPTARG ;;
    r ) rate=$OPTARG ;;
    e ) eth="-e $OPTARG" ;;
    F ) fastScan=1 ;;
    f ) ipFile=$OPTARG ;;
    \? ) echo "使用方式: $0 [-p 端口范围] [-r 扫描速率] [-e 网络接口] [-F] [-f IP文件] IP地址" ;;
  esac
done
shift $((OPTIND -1))

# 函数：执行扫描
scan_ip() {
    local myip=$1
    local outputFile="./scan_all.$myip.reslt"

    if [ $fastScan -eq 1 ]; then
        echo "对 $myip 执行快速扫描..."
        nmap -sCV -F -A -O $myip | tee "$outputFile"
    else
        echo "对 $myip 执行端口扫描..."
        if [ -z "$eth" ]; then
            port=$(masscan -p "$ports" --rate "$rate" "$myip" | grep "Disco" | cut -d ' ' -f 4 | cut -d '/' -f 1 | tr "\n" ',' | sed 's/,$//')
        else
            port=$(masscan -p "$ports" $eth --rate "$rate" "$myip" | grep "Disco" | cut -d ' ' -f 4 | cut -d '/' -f 1 | tr "\n" ',' | sed 's/,$//')
        fi

        if [ -z "$port" ]; then
            echo "未发现 $myip 的开放端口。"
            return
        fi

        echo "对 $myip 发现的端口: $port"
        echo "正在执行详细扫描..."
        nmap -sCV -p"$port" -A -O "$myip" | tee "$outputFile"
    fi
}

# 执行扫描
if [ ! -z "$ipFile" ]; then
    # 从文件读取IP地址并批量扫描
    while IFS= read -r ip; do
        scan_ip "$ip"
    done < "$ipFile"
elif [ $# -gt 0 ]; then
    # 执行单个IP的扫描
    scan_ip "$1"
else
    echo "错误: 必须提供IP地址或IP地址文件"
    exit 1
fi

