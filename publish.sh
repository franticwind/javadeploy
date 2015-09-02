#!/bin/sh
#
#Author: fengli
#Date: 2015-08-09
#Description: 发布脚本公共方法
#Usage:
#
# 依赖expect  yum install expect 

current_path=`pwd`
#项目git地址基地址
git_url="git@git.putao.so:ptcloud/$project_name.git"

#备份目录
backup_path="/mnt/deploy/publish_backup"
  
#发布日志路径
public_log="/mnt/deploy/publish_backup/publish.log"

version=""

#编译临时目录，根据实际情况做调整
project_tmp_base_path="/mnt/deploy/putao"
#拼接项目编译临时目录
project_tmp_path="$project_tmp_base_path/$project_name"
war_path="$project_tmp_path/$war_module/target/$war_name"

#记录日志
function log()
{
    now=`date +"%Y-%m-%d %H:%M:%S"`
    echo "$now $1"
    echo "$now $1" >> $public_log
}

#更新代码
function update_code()
{
    cd $project_tmp_base_path
    # 删除旧文件
    rm -rf $project_tmp_path
    log "下载代码 ... git clone --branch $1 --depth 1 $git_url"
    # 基于分支或者tag下载代码
    git clone --branch $1 --depth 1 $git_url
    sleep 5s
    log "更新代码完成！"
}

#编译代码
function complie()
{
    log "开始编译项目 mvn clean install -Dmaven.test.skip=true -P$project_env ... "
    cd $project_tmp_path 
    mvn clean install -Dmaven.test.skip=true -P$project_env
    log "编译项目完成！"
}

#传输发布文件
function remote_copy()
{
    log "开始传输war包 ... "
    cd $current_path
    ./remote-cp.sh "$1" "$2" "$3" "$4" "$5" "$6"
    log "传输war包完成！"
    
    read -p "输入回车继续发布：" next
    if [ "$next" = "" ]
    then
        #重启服务器
        restart "$1" "$2" "$3" "$4" "$6" "$7"
    else
        log "终止发布退出！"
    fi
}

#重启服务器
function restart()
{
    #解压缩war
    log "解压war包 ... "
    ./remote-exe.sh "$1" "$2" "$3" "$4" "rm -rf $5/WEB-INF; rm -rf $5/META-INF;unzip $5/$war_name -d $5; exit"
    log ">>>>>>>>>>>>>>停止服务器 ... "
    ./remote-exe.sh "$1" "$2" "$3" "$4" "cd $6 ; ./bin/shutdown.sh; tail -f $6/logs/catalina.out; "
    ./remote-exe.sh "$1" "$2" "$3" "$4" "cd $6 ; ps -ef | grep $6 | grep -v grep |awk -F ' ' '{print \$2}' | xargs kill -9; exit "
    log ">>>>>>>>>>>>>>重启服务器 ... "
    ./remote-exe.sh "$1" "$2" "$3" "$4" "ps -ef | grep $6 | grep -v grep |awk -F ' ' '{print $2}' | xargs kill -9; cd $6 ; ./bin/startup.sh; tail -f $6/logs/catalina.out; "
    log "$1 发布完成！"
}

function publish()
{
    version="$1"
    # 更新代码
    update_code $1
    # maven编译代码
    complie
    
    # 本地备份
    log "备份： cp $war_path $backup_path/$war_name.$version"
    cp "$war_path" $backup_path/"$war_name"."$version"
    
    read -p "输入回车继续发布：" next
    if [ "$next" = "" ]
    then
        #开始传输文件，遍历配置的节点
        len=${#ip[@]}
        for ((i=0;i<$len;i++));do
            remote_copy "${ip[$i]}" "${port[$i]}" "${user[$i]}" "${psw[$i]}" "${war_path[$i]}" "${app_path[$i]}" "${tomcat_path[$i]}"
        done
    else
        log "终止发布退出！"
    fi
}

#发布入口 $1 标签号或者分支名称
function main()
{
    echo "tag : $1 "
    if [ "$1" !=  "" ]
    then
        publish $1
    else
        echo "输入git 分支和标签不能为空！终止发布退出！"
    fi
}

