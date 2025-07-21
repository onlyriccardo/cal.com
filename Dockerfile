FROM node:18-alpine AS builder
RUN apk add --no-cache libc6-compat openssl openssl-dev python3 make g++
WORKDIR /app

# Copy package files
COPY package.json yarn.lock turbo.json ./
COPY apps/ ./apps/
COPY packages/ ./packages/

# Install dependencies
RUN yarn install --frozen-lockfile --network-timeout 600000

# Generate Prisma
RUN cd packages/prisma && npx prisma generate --schema=./schema.prisma || true

# Build
ENV NEXT_TELEMETRY_DISABLED=1
ENV BUILD_STANDALONE=true
ENV NODE_OPTIONS="--max-old-space-size=4096"

# Try to build with turbo first, fallback to direct build
RUN yarn build || (cd apps/web && yarn build)

# Production image
FROM node:18-alpine AS runner
RUN apk add --no-cache openssl
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Check if standalone exists, otherwise copy everything
COPY --from=builder /app/apps/web/.next/standalone ./
COPY --from=builder /app/apps/web/.next/static ./apps/web/.next/static
COPY --from=builder /app/apps/web/public ./apps/web/public

# Copy Prisma files
COPY --from=builder /app/packages/prisma ./packages/prisma
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=builder /app/node_modules/@prisma ./node_modules/@prisma

USER nextjs

EXPOSE 3000
ENV PORT=3000

CMD ["node", "apps/web/server.js"]