# syntax=docker/dockerfile:1

FROM node:24-bookworm-slim AS base

ENV PNPM_HOME=/pnpm
ENV PATH=$PNPM_HOME:$PATH
ENV HUSKY=0

RUN corepack enable

FROM base AS dependencies

WORKDIR /app

COPY package.json pnpm-lock.yaml ./
COPY scripts/sync-omc-directives.mjs ./scripts/sync-omc-directives.mjs

RUN --mount=type=cache,id=pnpm-store,target=/pnpm/store \
    pnpm install --frozen-lockfile

FROM base AS builder

WORKDIR /app

COPY --from=dependencies /app/node_modules ./node_modules
COPY . .

ENV NEXT_TELEMETRY_DISABLED=1

ARG BUILD_CONFIG_REVISION=local

RUN --mount=type=secret,id=app_env,target=/app/.env.production \
    echo "build-config-revision=${BUILD_CONFIG_REVISION}" \
    && pnpm build \
    && find /app/.next/standalone \
        -maxdepth 1 \
        -type f \
        -name '.env*' \
        -delete

FROM node:24-bookworm-slim AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV HOSTNAME=0.0.0.0
ENV PORT=3000

RUN groupadd --system --gid 1001 nodejs \
    && useradd --system --uid 1001 --gid nodejs nextjs

COPY --from=builder --chown=nextjs:nodejs /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

RUN test -z "$(find /app -maxdepth 2 -type f -name '.env*' -print -quit)"

USER nextjs

EXPOSE 3000

CMD ["node", "server.js"]
