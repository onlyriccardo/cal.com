FROM node:18-alpine AS builder
RUN apk add --no-cache libc6-compat openssl python3 make g++
WORKDIR /app

# Enable Yarn 3
RUN corepack enable
RUN corepack prepare yarn@3.4.1 --activate

# Copy all files
COPY . .

# Install dependencies
RUN yarn install --immutable

# Generate Prisma
RUN cd packages/prisma && npx prisma generate

# Build with standalone output
ENV NEXT_TELEMETRY_DISABLED=1
ENV BUILD_STANDALONE=true
RUN yarn workspace @calcom/web build

# Production image
FROM node:18-alpine
RUN apk add --no-cache openssl
WORKDIR /app

ENV NODE_ENV=production

# Copy standalone build
COPY --from=builder /app/apps/web/.next/standalone ./
COPY --from=builder /app/apps/web/.next/static ./apps/web/.next/static
COPY --from=builder /app/apps/web/public ./apps/web/public

EXPOSE 3000
ENV PORT=3000

CMD ["node", "apps/web/server.js"]