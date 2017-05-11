#!/bin/bash
#模式一：分区并WDCP数据迁移
# ↓ 磁盘分区
fdisk_state(){
	# ↓ 检测磁盘是否拥有分区
	status (){
		m=`fdisk -l $1 | grep "$1[1-9]"`
		if [ "$m" = "" ]; then
			echo "磁盘没有分区！"
			pid=0
		else 
			echo "磁盘已经拥有分区$1"1""
			pid=1
		fi
	}
	# ↓ 对磁盘进行分区
	start(){
m=`fdisk -l $1 | grep "$1[1-9]"`
# ↓ 判断磁盘是否分区，没有则执行分区，有则跳过分区的步骤
if [ "$m" = "" ];then
echo "u
n
p
1


w
" | fdisk $1 && mkfs.ext4 "$1"1""
echo "已经分区：$1"1""
pid=1
fi
}
	# ↓ 删除磁盘分区
	stop(){
	m=`fdisk -l $1 | grep "$1[1-9]"`
	# ↓ 判断磁盘是否分区，没有则执行分区，有则跳过分区的步骤
if [ "$m" != "" ];then
echo "d
w
" | fdisk $1 
echo "已经删除所有分区！"
pid=1
fi
}
	case "$1" in
		status)
			status $2
			;;
		start)
			start $2
			;;
		stop)
			stop $2
			;;
		*)
		;;
	esac
return $pid
}
# ↓ 针对centos7
mv_www_centos7(){
	systemctl stop mysqld
	systemctl stop httpd 
	systemctl stop nginxd
	systemctl stop wdcp
	systemctl stop wdapache
	systemctl stop memcached
	systemctl stop pureftpd
	if [ ! -d "/xpxp" ]; then
		mkdir /xpxp
	fi
	mount $1"1" /xpxp
	c=`ps -ef | grep /www`
	if [ "$c" == "" ];then
		mv /www/* /xpxp/
		u=`umount /xpxp`
		if [ "$u" == "" ];then
			mount -t ext4 $1"1" /www
		fi
	else 
		echo "未成功运行！"
	fi
	# 数据迁移完成,启动服务
	systemctl start mysqld
	systemctl start httpd
	systemctl start nginxd
	systemctl start wdcp
	systemctl start wdapache
	systemctl start memcached
	systemctl start pureftpd
	df -h | grep /www
}
# ↓ 针对centos6
mv_www_centos6(){
	service mysqld stop
	service httpd stop
	service nginxd stop
	service wdcp stop
	service wdapache stop
	service memcached stop
	service pureftpd stop
	if [ ! -d "/xpxp" ]; then
		mkdir /xpxp
	fi
	mount $1"1" /xpxp
	c=`ps -ef | grep /www`
	if [ "$c" == "" ];then
		mv /www/* /xpxp/
		u=`umount /xpxp`
		if [ "$u" == "" ];then
			mount -t ext4 $1"1" /www
		fi
	else 
		echo "未成功运行！"
	fi
	# 数据迁移完成,启动服务
	service mysqld start
	service httpd start
	service nginxd start
	service wdcp start
	service wdapache start
	service memcached start
	service pureftpd start
	df -h | grep /www
}
if [ "$1" = "" ]; then
	echo "请带上磁盘名称：如./$0 /dev/sda"
	exit 0
fi
# ↓ 获得系统的名称
x_release=`cat /etc/redhat-release | awk '{printf $1}'`
# ↓ 获得系统的版本编号
x=`cat /etc/redhat-release | awk '{printf $4}' | cut -d "." -f 1`
if [ "$x_release" != "CentOS" ] || [ "$x" != "6" ] && [ "$x" != "7" ];then 
	echo "只支持CentOS 6.*/7.*"
	exit 0
fi

echo "脚本将自动分区并迁移数据"
echo "1.磁盘已经分区则不会执行任何操作"
echo "2.分区大小一定要比/www目录所占空间大"
echo "3.请事先备份数据,以免出现错误时数据丢失"
echo "4.BUG可以来我的留言板留言"
echo "继续/放弃 (y/n)"
read hehe
if [ "$hehe" == "y" ];then 
	x=`fdisk -l $1 | wc -m`
	if [ "$x" == "0" ];then
		echo "read error!"
		exit 0
	elif [ "$x" == "" ];then
		echo "ERROR:没有这块磁盘，或者输入不正确。例:/dev/sda"
		exit 0
	else 
		echo "好的，脚本将继续运行"
	fi 
	# ↓ 交给fdisk_state函数检测磁盘是否有分区,有则返回 1 ,没有则返回 0 
	fdisk_state status $1
	# ↓ 接收 fdisk_state 函数的返回值
	fdisk_pid=$?
	if [ "$fdisk_pid" == "0" ];then
		# ↓ 由fdisk_state 函数对磁盘进行分区
		fdisk_state start $1
		
		if [ "$x" == "7" ];then
			mv_www_centos7 $1
		elif [ "$x" == "6" ];then
			mv_www_centos6 $1
		else 
			echo "error!"
		fi
	elif [ "$fdisk_pid" == "1" ];then
		echo "脚本未作任何操作,因为磁盘已经拥有分区"
	else 
		echo "error!"
	fi
	exit 0
elif [ "$hehe" == "n" ];then
	echo "你已经放弃数据迁移的操作"
	exit 0
else 
	echo "请输入正确的选项：继续/放弃(y/n)"
	exit 0
fi 
exit 0