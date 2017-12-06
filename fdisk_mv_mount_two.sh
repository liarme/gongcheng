#!/bin/bash
#模式一：分区并WDCP数据迁移
# ↓ 磁盘分区
function fdisk_state(){
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
if [ "$m" == "" ];then
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
function mv_stop(){
	/www/wdlinux/init.d/mysqld stop
	/www/wdlinux/init.d/httpd stop
	/www/wdlinux/init.d/nginxd stop
	/www/wdlinux/wdcp/wdcp.sh stop
	/www/wdlinux/init.d/pureftpd stop
	/www/wdlinux/init.d/memcached stop
	phpfpm2=`ps -ef | grep /www/wdlinux/phps/52/etc/php-fpm.conf | grep -v grep`
	if [ "$phpfpm2" != "" ];then
		/www/wdlinux/phps/52/bin/php-fpm stop
	fi 
	phpfpm3=`ps -ef | grep /www/wdlinux/phps/53/etc/php-fpm.conf | grep -v grep`
	if [ "$phpfpm3" != "" ];then
		/www/wdlinux/phps/53/bin/php-fpm stop
	fi 
	phpfpm4=`ps -ef | grep /www/wdlinux/phps/54/etc/php-fpm.conf | grep -v grep`
	if [ "$phpfpm4" != "" ];then
		/www/wdlinux/phps/54/bin/php-fpm stop
	fi 
	phpfpm5=`ps -ef | grep /www/wdlinux/phps/55/etc/php-fpm.conf | grep -v grep`
	if [ "$phpfpm5" != "" ];then
		/www/wdlinux/phps/55/bin/php-fpm stop
	fi 
	phpfpm6=`ps -ef | grep /www/wdlinux/phps/56/etc/php-fpm.conf | grep -v grep`
	if [ "$phpfpm6" != "" ];then
		/www/wdlinux/phps/56/bin/php-fpm stop
	fi 
	phpfpm7=`ps -ef | grep /www/wdlinux/phps/70/etc/php-fpm.conf | grep -v grep`
	if [ "$phpfpm7" != "" ];then
		/www/wdlinux/phps/70/bin/php-fpm stop
	fi 
	phpfpm1=`ps -ef | grep /www/wdlinux/phps/71/etc/php-fpm.conf | grep -v grep`
	if [ "$phpfpm1" != "" ];then
		/www/wdlinux/phps/71/bin/php-fpm stop
	fi
}
function mv_start(){
	/www/wdlinux/init.d/mysqld start
	/www/wdlinux/init.d/httpd start
	/www/wdlinux/init.d/nginxd start
	/www/wdlinux/wdcp/wdcp.sh start
	/www/wdlinux/init.d/pureftpd start
	/www/wdlinux/init.d/memcached start
	/www/wdlinux/wdcp/phps/start.sh
}
function mv_fdisk(){
	c=`ps -ef | grep /www | grep -v grep`
	if [ "$c" == "" ];then
		fdisk_if $1
		if [ ! -d "/xpxp" ]; then
			mkdir /xpxp
		fi
		mount $1"1" /xpxp
		mv /www/* /xpxp/
		u=`umount /xpxp`
		if [ "$u" == "" ];then
			mount -t ext4 $1"1" /www
		fi
		df -h | grep /www
		fstab=`cat /etc/fstab | grep $1 | grep -v grep`
		if [ "$fstab" == "" ];then
			echo $1"1               /www                    ext4    defaults        0 0">>/etc/fstab
		fi
		cat /etc/fstab
	else 
		echo "未成功运行！"
		umount /xpxp
		rm -rf /xpxp
	fi
}
function fdisk_if(){
	# ↓ 交给fdisk_state函数检测磁盘是否有分区,有则返回 1 ,没有则返回 0 
	fdisk_state status $1
	# ↓ 接收 fdisk_state 函数的返回值
	fdisk_pid=$?
	if [ "$fdisk_pid" == "0" ];then
		# ↓ 由fdisk_state 函数对磁盘进行分区
		fdisk_state start $1
	elif [ "$fdisk_pid" == "1" ];then
		echo "脚本未作任何操作,因为磁盘已经拥有分区"
		mv_start
		exit 0
	else 
		echo "error!"
		exit 0
	fi
}
if [ "$1" = "" ]; then
	echo "请带上磁盘名称：如./$0 /dev/sda"
	exit 0
fi
# ↓ 获得系统的名称
x_release=`cat /etc/redhat-release | awk '{printf $1}'`
# ↓ 获得系统的版本编号
x=`cat /etc/redhat-release | awk '{printf $4}' | cut -d "." -f 1`
if [ "$x_release" != "CentOS" ] || [ "$x" != "6" ] && [ "$x" != "7" ] && [ "$x" != "(Final)" ];then 
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
	
	disk=`fdisk -l $1 | wc -m`
	if [ "$disk" == "0" ];then
		echo "read error!"
		exit 0
	elif [ "$disk" == "" ];then
		echo "ERROR:没有这块磁盘，或者输入不正确。例:/dev/sda"
		exit 0
	else 
		tab=`df -h | grep /www`
		if [ "$tab" != "" ];then
			echo "/www已经挂在"$1"1"
			exit 0
		fi
		echo "好的，脚本将继续运行"
	fi 
	mv_stop
	mv_fdisk $1
	mv_start
elif [ "$hehe" == "n" ];then
	echo "你已经放弃数据迁移的操作"
	exit 0
else 
	echo "请输入正确的选项：继续/放弃(y/n)"
	exit 0
fi 
exit 0