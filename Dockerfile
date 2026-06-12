# Runtime image para el binario ya compilado para linux/arm64.
# El binario se compila en el host con cmd/build-pi.sh.
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates tzdata \
    && rm -rf /var/lib/apt/lists/*

ENV TZ=America/Argentina/Buenos_Aires
WORKDIR /app

COPY dist/vero-palmieri-portfolio /app/vero-palmieri-portfolio
RUN chmod +x /app/vero-palmieri-portfolio

CMD ["/app/vero-palmieri-portfolio", "serve", "--http=0.0.0.0:8090"]
