#!/bin/shell
#一件完成wdcp3.2版本的安装
#
#yum update -y
#yum install -y wget
function install(){
	wget http://download.niexin.me/wdcp_soft/lanmp_v3.2.tar.gz
	tar zxf lanmp_v3.2.tar.gz
	sh lanmp.sh > /dev/null
	# sh lib/phps.sh
	# sh lib/phps_zend.sh
	# sh lib/phps_redis.sh
	# sh lib/phps_memcache.sh
}
time install