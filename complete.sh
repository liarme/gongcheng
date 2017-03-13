#!/bin/bash
#模式一：分区并WDCP数据迁移
# ↓ 磁盘挂载on/off
mount_state(){
	start(){
		# ↓ 读取磁盘挂载信息
		disk_sda_dfh=`df -h | grep $1 | awk '{print $1}'`
		# ↓ 判断磁盘是否挂载，若为空就执行挂载，反则不执行
		if [ "$disk_sda_dfh" = "" ]; then
			# ↓ $2代表WDCP的目录，默认/www
			`mount $1"1" $2`
			# ↓ 读取磁盘挂载信息
			disk_sdb_dfh=`df -h | grep $1 | awk '{print $1}'`
			# ↓ 判断磁盘是否挂载，若为空则挂载失败，反则成功
			if [ "disk_sdb_dfh" != "" ]; then
				# ↓ 成功
				echo "磁盘挂载成功!"
				pid=1
			else 
				# ↓ 失败
				echo "磁盘挂载失败!"
				pid=0
			fi 
		else 
			# ↓ 磁盘已经挂载
			echo "磁盘已经挂载!"
			pid=0
		fi 
		return $pid
	}
	stop(){
		# ↓ 读取磁盘挂载信息
		disk_sda_dfh=`df -h | grep $1 | awk '{print $1}'`
		# ↓ 判断磁盘是否挂载，不为空就执行解除挂载，反则不执行
		if [ "$disk_sda_dfh" != "" ];then 
			# ↓ 获取磁盘所挂载的目录
			disk_sde_dfh=`df -h | grep $1 | awk '{print $6}'`
			# ↓ 判断磁盘挂载的目录是否有效
			if [ "$disk_sde_dfh" != "" ]; then
				# ↓ 取消该磁盘的挂载
				`umount $disk_sde_dfh`
				disk_sda_dfh=`df -h | grep $1 | awk '{print $1}'`
				if [ "$disk_sda_dfh" = "" ]; then 
					# ↓ 打印成功的消息
					echo "取消挂载成功!"
					pid=1
				else
					# ↓ 打印失败的消息
					echo "取消挂载失败!"
					echo "请结束$disk_sde_dfh目录下正在运行的程序"
					pid=0
				fi 
			else
				echo "没有找到磁盘挂载的目录，难道这是一个错误？"
				pid=0
			fi 
		else
			# ↓ 打印磁盘没有挂载的消息 
			echo "磁盘没有挂载"
			pid=1
		fi 
		return $pid
	}
	status(){
		disk_sda_dfh=`mount | grep $1`
		if [ "$disk_sda_dfh" = "" ]; then
			echo "磁盘没有挂载！"
			pid=0
		else
			echo "$disk_sda_dfh"
			pid=1
		fi 
		return $pid
	}
	case "$1" in
		start)
			start $2
			;;
		stop)
			stop $2
			;;
		status)
			status $2
			;;
		*)
			echo $"Usage: $prog {start|stop|status}"
			RETVAL=1
	esac
}
# ↓ 扩展磁盘
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
# ↓ 得到磁盘的分区编号 如：/dev/sda1
disk_sdb_fdisk=`fdisk -l $1 | grep $1[1-9] | awk '{print $1}'`
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
		e2fsck -f $disk_sdb_fdisk
		resize2fs $disk_sdb_fdisk
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
	# disk_yun_parted $1
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
if [ "$1" = "" ]; then
	echo "请带上磁盘名称：如./$0 /dev/sda"
	exit 0
fi
echo "脚本将自动分区并迁移数据"
echo "1.磁盘已经分区则不会再分区"
echo "2.分区大小一定要比/www目录所占空间大"
echo "3.请事先备份数据,以免出现错误时数据丢失"
echo "4.一切的一切与作者无关"
read $hehe
echo $hehe
exit 0
x=`fdisk -l $1 | wc -m`
if [ "$x" = "0" ];then
	echo "read error!"
	exit 0
elif [ "$x" = "" ];then
	echo "ERROR:没有这块磁盘，或者输入不正确。例:/dev/sda"
	exit 0
else 
	echo "好的，脚本将继续运行"
fi 

parted_state status_parted

fdisk_state status $1
fdisk_pid=$?
if [ "$fdisk_pid" = "0" ];then
	fdisk_state start $1
elif [ "$fdisk_pid" = "1" ];then
	m=`fdisk -l /dev/sdc | grep "/dev/sdc:" | awk '{printf $3 $4}' | cut -f 1 -d ","` 
	m_one=`fdisk -l /dev/sdc | grep "/dev/sdc:" | awk '{printf $3}' | cut -f 1 -d ","` 
	x=`du -sh --block-size G /www | awk '{print $1}' | cut -f 1 -d "G"`
	parted_state status $1
	disk_sda_parted_two=`cat xp.txt | grep -w ' 1 ' | awk '{print $3}'`
	rm -rf ./xp.txt
	if [ "$m" = "$disk_sda_parted_two" ];then
		if [ "$m_one" > "$x" ];then
			echo "磁盘分区大小符合要求！"
		else 
			echo "Error!"
		fi
	else 
		if [ "$disk_sda_parted_two" > "$x" ];then
			echo "磁盘分区大小符合要求！"
		else 
			echo "Error!"
		fi
		# echo "error!"
		# echo $m
		# echo $disk_sda_parted_two
	fi
else 
	echo "error!"
fi
exit 0 