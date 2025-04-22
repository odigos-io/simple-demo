FROM php:8.2-cli
WORKDIR /app
COPY . /app

RUN curl -sS https://getcomposer.org/installer | php && \
  mv composer.phar /usr/local/bin/composer && \
  composer install

CMD ["php", "-S", "0.0.0.0:8080"]
