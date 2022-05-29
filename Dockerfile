FROM php:7.4-apache-buster

RUN apt-get update && apt-get install -y --no-install-recommends \
		bzip2 \
		gnupg \
		dirmngr \
		libcurl4-openssl-dev \
		libfreetype6-dev \
		libicu-dev \
		libjpeg-dev \
		libldap2-dev \
		libmemcached-dev \
		libpng-dev \
		libpq-dev \
		libxml2-dev \
		libzip-dev \
		unzip \
		libmagickwand-dev \
		libevent-dev \
		libmcrypt-dev \
		libwebp-dev \
		libgmp-dev \
	&& rm -rf /var/lib/apt/lists/*

RUN set -ex; \
    debMultiarch="$(dpkg-architecture --query DEB_BUILD_MULTIARCH)"; \
    docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp; \
    docker-php-ext-configure ldap --with-libdir="lib/$debMultiarch"; \
    docker-php-ext-install -j "$(nproc)" \
		bcmath \
		exif \
		gd \
		intl \
		ldap \
		opcache \
		pcntl \
		pdo_mysql \
		zip \
		gmp

RUN apt-get update && apt-get install -y \
	git \
	nano \
	unzip \
	wget \
	libxrender1 \
	libfontconfig1 \
	libxext6 \
	ssl-cert \
	smbclient \
	libsmbclient-dev \
	&& rm -rf /var/lib/apt/lists/*

RUN set -ex; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	\
        pecl install apcu; \
        pecl install memcached; \
        pecl install redis; \
        pecl install smbclient; \
        pecl install imagick; \
    docker-php-ext-enable \
        apcu \
        memcached \
        redis \
        imagick \
    ; \
    rm -r /tmp/pear; \
    \
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
    apt-mark auto '.*' > /dev/null; \
    apt-mark manual $savedAptMark; \
    ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
        | awk '/=>/ { print $3 }' \
        | sort -u \
        | xargs -r dpkg-query -S \
        | cut -d: -f1 \
        | sort -u \
        | xargs -rt apt-mark manual; \
    \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    rm -rf /var/lib/apt/lists/*

RUN { \
        echo 'opcache.enable=1'; \
        echo 'opcache.interned_strings_buffer=16'; \
        echo 'opcache.max_accelerated_files=10000'; \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.save_comments=1'; \
        echo 'opcache.revalidate_freq=60'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini; \
    \
    echo 'apc.enable_cli=1' >> /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini; \
    \
    { \
        echo 'memory_limit=512M'; \
        echo 'upload_max_filesize=512M'; \
        echo 'post_max_size=512M'; \
    } > /usr/local/etc/php/conf.d/nextcloud.ini


RUN a2enmod headers rewrite remoteip ;\
    {\
     echo RemoteIPHeader X-Real-IP ;\
     echo RemoteIPTrustedProxy 10.0.0.0/8 ;\
     echo RemoteIPTrustedProxy 172.16.0.0/12 ;\
     echo RemoteIPTrustedProxy 192.168.0.0/16 ;\
    } > /etc/apache2/conf-available/remoteip.conf;\
    a2enconf remoteip

RUN a2enmod ssl

RUN a2ensite default-ssl.conf

ENV NEXTCLOUD_VERSION 24.0.1

VOLUME /var/www/html

RUN set -eux; \
	curl -fL -o nextcloud.tar.bz2 "https://download.nextcloud.com/server/releases/nextcloud-${NEXTCLOUD_VERSION}.tar.bz2"; \
	tar -xjf nextcloud.tar.bz2 -C /usr/src/; \
	rm nextcloud.tar.bz2

COPY docker-entrypoint.sh /usr/local/bin/

RUN ["chmod", "+x", "/usr/local/bin/docker-entrypoint.sh"]

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["apache2-foreground"]

