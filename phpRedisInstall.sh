#!/bin/bash
curl https://pecl.php.net/get/redis-6.0.2.tgz --output redis-6.0.2.tgz
tar xzf redis-6.0.2.tgz
cd redis-6.0.2
phpize
./configure
make
make install