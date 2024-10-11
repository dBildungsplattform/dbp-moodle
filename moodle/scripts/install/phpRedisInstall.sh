#!/bin/bash
curl https://pecl.php.net/get/redis-6.0.2.tgz --output /tmp/redis-6.0.2.tgz
cd /tmp
tar xzf /tmp/redis-6.0.2.tgz
rm /tmp/redis-6.0.2.tgz
cd /tmp/redis-6.0.2
phpize
./configure
make
make install