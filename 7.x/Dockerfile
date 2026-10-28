FROM alpine:3.20

ARG MONGOTOOLS_VERSION=100.9.5

RUN apk add --no-cache bash curl ca-certificates libintl krb5-libs libgcc libstdc++ && \
    curl -sfL "https://fastdl.mongodb.org/tools/db/mongodb-database-tools-rhel80-x86_64-${MONGOTOOLS_VERSION}.tgz" -o /tmp/tools.tgz && \
    tar -xzf /tmp/tools.tgz -C /tmp && \
    cp /tmp/mongodb-database-tools-*/bin/mongodump /usr/local/bin/ && \
    rm -rf /tmp/tools*

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /tmp/backup

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
