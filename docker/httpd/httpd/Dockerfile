FROM httpd:2.4

MAINTAINER Lindsay Stevens (lindsay.stevens.au@gmail.com)

# Add user and group first to make sure their IDs get assigned consistently
# regardless of whatever dependencies get added
RUN groupadd -r httpd && useradd -r -g httpd httpd

# grab gosu for easy step-down from root (no purge)
RUN gpg --keyserver pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates wget && rm -rf /var/lib/apt/lists/* \
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture)" \
	&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture).asc" \
	&& gpg --verify /usr/local/bin/gosu.asc \
	&& rm /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu

# Copy conf files and remove default webapps
ADD /conf/ docker/
RUN rm -rf htdocs/* \
    && cp -R docker/httpd/* conf/ \
    && chmod +rx docker/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/apache2/docker/docker-entrypoint.sh"]
EXPOSE 8080 8443
CMD ["httpd", "-DFOREGROUND"]
