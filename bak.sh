#!/bin/bash
parted_state(){
# ↓ 判断系统是否安装parted函数
status_parted(){
	yum_install_parted=`yum list installed | grep "parted"`
	if [ "$yum_install_parted" = "" ]; then 
		`yum -y install parted`
		yum_install_parted=`yum list installed | grep "parted"`
		if [ "$yum_install_parted" = "" ]; then 
			echo "安装失败"
		else
			echo "安装成功"
			# disk_yun_parted $1
		fi
	else 
		echo "已经安装，进行下一步!"
		# disk_yun_parted $1
	fi
}
status (){
echo "p
q
" | parted $1 > xp.txt
}

start (){
# ↓ 扩展磁盘的函数
parted_run(){
# ↓ 获取需要扩展的分区的Start值，没有对齐的原因是加上tab后执行命令会出错，不完美
echo "p
q
" | parted $1 > xp.txt
disk_sda_parted_two=`cat xp.txt | grep -w ' 1 ' | awk '{print $2}'`
# ↓ 执行扩展，理由同上 ↑
echo "rm 1
mkpart primary $disk_sda_parted_two -1
q
" | parted $1
		e2fsck -f $1"1"
		resize2fs $1"1"
		#最后删除获取Start值时生成的临时文件
		rm -rf xp.txt
	}
	disk_yun_parted(){
		# ↓ 获取分区号 如：/dev/sda1
		disk_sda_dfh=`df -h | grep $1 | awk '{print $1}'`
		# 判断分区是否挂载，挂载则解除挂载后执行扩展，反则直接执行扩展
		if [ "$disk_sda_dfh" != "" ]; then 
			disk_state stop $1
			parted_run $1
		else 
			parted_run $1
		fi
	}
	disk_yun_parted $1
}
	case "$1" in
		start)
			start $2
			;;
		status)
			status $2
			;;
		status_parted)
			status_parted
			;;
		*)
			;;
	esac
	return $pid
}
parted_state status_parted
service mysqld stop
service httpd stop
service nginxd stop
service wdcp stop
service memcached stop
service pureftpd stop
disk_sda_dfh=`mount | grep /www | awk '{print $1}' | cut -d "1" -f 1`
ccp=$disk_sda_dfh"1"
c=`umount /www`
if [ "$c" = "" ];then
	x=`mount | grep "/www" | awk '{print $1}' | cut -d "1" -f 1`
	parted_state start $disk_sda_dfh
	mount -t ext4 $ccp /www
else 
	echo "未成功运行！"
fi
service mysqld start
service httpd start
service nginxd start
service wdcp start
service memcached start
service pureftpd start
df -lh | grep /www
exit 0