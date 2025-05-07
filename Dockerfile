FROM alpine:latest

RUN apk add --no-cache bash curl cronie jq

COPY bin/update.sh /app/update.sh
COPY mycron /etc/mycron


RUN chmod +x /app/update.sh

RUN crontab /etc/mycron

CMD ["crond", "-f", "/dev/stdout"]
