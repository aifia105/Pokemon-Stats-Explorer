FROM node:24.15.0 AS deps

WORKDIR /app

COPY package.json package-lock.json ./

RUN npm ci


FROM node:24.15.0 AS builder

RUN apt-get update && apt-get install -y git

WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .

ARG ENV=production

ENV NODE_ENV=$ENV
ENV NEXT_TELEMETRY_DISABLED=1


# build
RUN npm run build


FROM node:24.15.0 AS runner

WORKDIR /app

ARG ENV
ENV NODE_ENV=$ENV
ENV NEXT_TELEMETRY_DISABLED=1

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/.env.production ./.env

COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

ARG PORT=3000
EXPOSE $PORT

ENV PORT=$PORT
ENV HOSTNAME="0.0.0.0"

CMD ["node", "server.js"]