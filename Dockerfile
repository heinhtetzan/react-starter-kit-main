FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV APP_ENV=production

# -------------------------
# System packages
# -------------------------
RUN apt update && apt install -y \
    ca-certificates \
    curl \
    wget \
    git \
    unzip \
    sqlite3 \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# -------------------------
# PHP 8.4
# -------------------------
RUN add-apt-repository ppa:ondrej/php -y && apt update && apt install -y \
    php8.4 \
    php8.4-cli \
    php8.4-sqlite3 \
    php8.4-pdo-sqlite \
    php8.4-mbstring \
    php8.4-xml \
    php8.4-bcmath \
    php8.4-curl \
    php8.4-zip \
    php8.4-intl \
    && rm -rf /var/lib/apt/lists/*

# -------------------------
# PHP upload size
# -------------------------
RUN echo "upload_max_filesize=50M" >> /etc/php/8.4/cli/php.ini \
 && echo "post_max_size=50M" >> /etc/php/8.4/cli/php.ini

# -------------------------
# Composer
# -------------------------
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# -------------------------
# Node.js
# -------------------------
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
 && apt install -y nodejs \
 && rm -rf /var/lib/apt/lists/*

# -------------------------
# App
# -------------------------
WORKDIR /var/www/html
COPY . .

RUN composer install --no-dev --optimize-autoloader
RUN npm install && npm run build

# -------------------------
# SQLite
# -------------------------
RUN mkdir -p database \
 && touch database/database.sqlite \
 && chown -R www-data:www-data storage bootstrap/cache database \
 && chmod -R 775 storage bootstrap/cache database

# -------------------------
# Expose artisan port
# -------------------------
EXPOSE 8000

# -------------------------
# Start Laravel
# -------------------------
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
