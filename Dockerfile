FROM node:lts-alpine AS builder

WORKDIR /app

COPY ./ /app

RUN --mount=type=cache,target=/root/.npm npm run bootstrap

FROM node:lts-alpine AS release

RUN apk update && apk upgrade && apk add --no-cache python3 py3-pip

WORKDIR /app

COPY --from=builder /app/dist /app/dist
COPY --from=builder /app/package.json /app/package.json
COPY --from=builder /app/package-lock.json /app/package-lock.json
COPY ./scripts/docker-entrypoint.sh /app/docker-entrypoint.sh

ENV NODE_ENV=production
ENV MCPO_PORT=8005
ENV PYTHONDONTWRITEBYTECODE=1

RUN npm ci --ignore-scripts --omit=dev \
    && python3 -m pip install --no-cache-dir --break-system-packages mcpo \
    && chmod +x /app/docker-entrypoint.sh \
    && npm uninstall -g npm

EXPOSE 8005

ENTRYPOINT ["/app/docker-entrypoint.sh"]
