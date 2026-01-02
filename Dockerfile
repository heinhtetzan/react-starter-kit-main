FROM ubuntu:latest

# Avoid prompts
ENV DEBIAN_FRONTEND=noninteractive

# System update + base tools
RUN apt-get update && apt-get install -y \
    software-properties-common \
    curl \
    git \
    unzip \
    vim \
    openssl \
    sqlite3 \
    libsqlite3-dev

# Add PHP repository (latest PHP available)
RUN add-apt-repository ppa:ondrej/php -y \
    && apt-get update

# Install PHP (no version pin)
RUN apt-get install -y \
    php \
    php-cli \
    php-fpm \
    php-mysql \
    php-sqlite3 \
    php-gd \
    php-xml \
    php-mbstring \
    php-curl \
    php-zip

# Install Node.js (one line)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php \
    -- --install-dir=/usr/local/bin --filename=composer

# Increase upload limits (CLI + FPM)
RUN sed -i 's/upload_max_filesize = .*/upload_max_filesize = 1000M/' /etc/php/*/cli/php.ini \
    && sed -i 's/post_max_size = .*/post_max_size = 1000M/' /etc/php/*/cli/php.ini \
    && sed -i 's/upload_max_filesize = .*/upload_max_filesize = 1000M/' /etc/php/*/fpm/php.ini \
    && sed -i 's/post_max_size = .*/post_max_size = 1000M/' /etc/php/*/fpm/php.ini

# Set working directory
WORKDIR /app

# Copy application
COPY . .

# Backend dependencies
RUN composer install --no-interaction --prefer-dist

# Frontend build
RUN npm install && npm run build

# SQLite database
RUN mkdir -p database \
    && touch database/database.sqlite

# Laravel setup
RUN php artisan key:generate \
    && php artisan migrate --force \
    && php artisan storage:link

# Permissions
RUN chmod -R 777 storage bootstrap/cache database

EXPOSE 8000

CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
