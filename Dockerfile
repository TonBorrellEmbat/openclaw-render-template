FROM node:22-slim

RUN apt-get update && apt-get install -y git curl procps lsof python3 make g++ cron tini && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev --prefer-online && npm cache clean --force

ENV PATH="/app/node_modules/.bin:$PATH"
ENV ALPHACLAW_ROOT_DIR=/data

RUN mkdir -p /data

EXPOSE 3000

# DenchClaw caches its Next.js standalone build under /data (persistent disk)
# at /data/.openclaw-dench/web-runtime/app/. Once that copy exists, every
# subsequent `denchclaw start` reuses it and ignores any fresh code in
# /app/node_modules/denchclaw/. That means our fork's UI changes only land
# the FIRST time the disk is provisioned. Wipe it on every container start
# so AlphaClaw's "runtime missing -> denchclaw update" fallback reinstalls
# from the current npm package each deploy.
ENTRYPOINT ["/usr/bin/tini", "--", "/bin/sh", "-c", "rm -rf /data/.openclaw-dench/web-runtime/app /root/.openclaw-dench/web-runtime/app 2>/dev/null; exec \"$@\"", "--"]
CMD ["alphaclaw", "start"]
