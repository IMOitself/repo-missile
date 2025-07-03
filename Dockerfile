FROM alpine:3.12

RUN apk add --no-cache git

COPY entrypoint.sh /entrypoint.sh

# I EDITED ON WINDOWS AND IT CRASHES BECAUSE OF THAT LIKE WHAT??
RUN sed -i 's/\r$//' /entrypoint.sh && \
    chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
