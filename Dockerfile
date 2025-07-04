FROM alpine:3.12

RUN apk add --no-cache git

COPY action.sh /action.sh

RUN sed -i 's/\r$//' /action.sh && chmod +x /action.sh

ENTRYPOINT ["/action.sh"]
