FROM alpine:latest

RUN apk add --no-cache bash curl cronie jq

COPY bin/update.sh /app/update.sh
COPY mycron /etc/mycron

# Aquí configuro la estructura necesaria para que funcione `update.sh` (pude hacerlo en el mismo pero ñe)
RUN mkdir /var/lib/update-cloudflare-dns/
RUN touch /var/lib/update-cloudflare-dns/current_ip.txt


RUN chmod +x /app/update.sh

RUN crontab /etc/mycron

CMD ["crond", "-f", "/dev/stdout"]
