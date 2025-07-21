FROM node:18-alpine AS builder
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Copy all files
COPY . .

# Install dependencies
RUN yarn install --frozen-lockfile

# Build the standalone version
ENV BUILD_STANDALONE=true
ENV NEXT_TELEMETRY_DISABLED=1
RUN yarn build

# Production image
FROM node:18-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Copy standalone build
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public
COPY --from=builder /app/packages/prisma ./packages/prisma

USER nextjs

EXPOSE 3000
ENV PORT=3000

CMD ["node", "server.js"]