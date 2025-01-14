FROM python:3.9.21-alpine3.21

WORKDIR /DanmakuRender

COPY . .

RUN set -ex \
    && apk add --no-cache curl nodejs ffmpeg npm rust cargo \
    && curl -O -L https://github.com/biliup/biliup-rs/releases/download/v0.2.1/biliupR-v0.2.1-x86_64-linux.tar.xz \
    && tar -xf biliupR-v0.2.1-x86_64-linux.tar.xz --strip-components=1 -C ./tools \
    && rm -rf biliupR-v0.2.1-x86_64-linux.tar.xz \
    && pip install -r requirements.txt \
    && apk del curl rust cargo \
    && rm -rf /var/cache/apk/*

    ENTRYPOINT ["python3", "-u", "main.py"]