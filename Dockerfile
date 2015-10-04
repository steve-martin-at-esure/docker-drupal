# Docker container for Drupal 8

FROM php:5.5-apache

RUN apt-get update
RUN apt-get install -yqq --no-install-recommends \
  rsyslog \
  supervisor \
  curl \
  cron \
  mysql-client \
  libpng-dev \
  ca-certificates \
  libsqlite3-dev \
  build-essential \
  git \
  ruby \
  ruby-dev \
  libfreetype6-dev \
  libjpeg62-turbo-dev \
  libpng12-dev \
  libmemcached-dev \
  && a2enmod rewrite \
  && a2enmod expires \
  && a2enmod headers \
  && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
  && docker-php-ext-install mysql pdo_mysql zip mbstring gd exif \
  && pecl install uploadprogress xdebug memcached \
  && echo extension=memcached.so > /usr/local/etc/php/conf.d/memcached.ini \
  && echo extension=uploadprogress.so > /usr/local/etc/php/conf.d/uploadprogress.ini \
  && apt-get clean autoclean && apt-get autoremove -y

COPY public/core/vendor/twig/twig/ext/twig /usr/lib/twig
WORKDIR /usr/lib/twig
RUN phpize && ./configure && make && make install
RUN echo extension=twig.so > /usr/local/etc/php/conf.d/twig.ini
WORKDIR /var/www

RUN gem install mailcatcher

COPY config/docker/web/rsyslog.conf /etc/rsyslog.conf

RUN ln -s ~www-data/web/vendor/bin/drush /usr/local/bin/drush
RUN ln -s ~www-data/web/vendor/bin/console /usr/local/bin/console
COPY config/docker/web/drushrc.php /etc/drush/drushrc.php
COPY config/docker/web/xdebug.sh xdebug.sh

ADD config/docker/web /docker
COPY config/docker/web/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN a2enmod ssl
COPY config/docker/web/crontab.txt /var/crontab.txt
RUN crontab /var/crontab.txt && chmod 600 /etc/crontab
COPY config/docker/web/default.conf /etc/apache2/sites-available/000-default.conf
RUN a2ensite 000-default.conf

COPY . /var/www/html

EXPOSE 80 443

CMD ["/usr/bin/supervisord"]