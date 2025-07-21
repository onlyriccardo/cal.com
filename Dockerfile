FROM node:18-alpine AS dependencies
RUN apk add --no-cache libc6-compat openssl python3 make g++
WORKDIR /app
COPY package.json yarn.lock ./
COPY apps/web/package.json ./apps/web/
COPY packages/prisma/package.json ./packages/prisma/
COPY packages/*/package.json ./packages/*/
RUN yarn install --frozen-lockfile

FROM node:18-alpine AS builder
RUN apk add --no-cache libc6-compat openssl
WORKDIR /app
COPY --from=dependencies /app/node_modules ./node_modules
COPY . .

# Generate Prisma
RUN npx prisma generate --schema=./packages/prisma/schema.prisma || true

# Build only what we need
ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=production
RUN cd apps/web && npm run build

FROM node:18-alpine AS runner
RUN apk add --no-cache openssl
WORKDIR /app

ENV NODE_ENV=production

# Copy built application
COPY --from=builder /app/apps/web/.next ./apps/web/.next
COPY --from=builder /app/apps/web/public ./apps/web/public
COPY --from=builder /app/apps/web/package.json ./apps/web/
COPY --from=builder /app/apps/web/next.config.js ./apps/web/
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/packages ./packages
COPY --from=builder /app/package.json ./

WORKDIR /app/apps/web
EXPOSE 3000

CMD ["npm", "start"]