FROM php:8.2-fpm
WORKDIR /app
COPY . /app

RUN apt-get update && apt-get install -y \
  git \
  curl \
  zip \
  unzip

RUN docker-php-ext-install pcntl

RUN curl -sS https://getcomposer.org/installer | php && \
  mv composer.phar /usr/local/bin/composer && \
  composer install

EXPOSE 9000
CMD ["php-fpm"]
