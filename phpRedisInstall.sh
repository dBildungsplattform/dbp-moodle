#!/bin/bash
curl https://pecl.php.net/get/redis-6.0.2.tgz
ls
tar xzf redis-6.0.2.tgz
ls
cd redis-6.0.2
ls
phpize
./configure
make
make install