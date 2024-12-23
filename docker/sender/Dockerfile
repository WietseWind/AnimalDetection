FROM alpine:3.19
RUN apk add --no-cache netcat-openbsd bash
WORKDIR /app
COPY app.sh .
RUN chmod +x app.sh
CMD ["./app.sh"]