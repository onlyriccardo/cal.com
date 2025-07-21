FROM node:18-alpine AS builder
RUN apk add --no-cache libc6-compat openssl openssl-dev
WORKDIR /app

# Copy all package files first
COPY package.json yarn.lock ./
COPY apps/web/package.json ./apps/web/
COPY packages/prisma/package.json ./packages/prisma/
COPY packages/lib/package.json ./packages/lib/
COPY packages/ui/package.json ./packages/ui/
COPY packages/config/package.json ./packages/config/
COPY packages/tsconfig/package.json ./packages/tsconfig/
COPY packages/app-store/package.json ./packages/app-store/
COPY packages/app-store-cli/package.json ./packages/app-store-cli/
COPY packages/dayjs/package.json ./packages/dayjs/
COPY packages/emails/package.json ./packages/emails/
COPY packages/embed-core/package.json ./packages/embed-core/
COPY packages/embed-react/package.json ./packages/embed-react/
COPY packages/embed-snippet/package.json ./packages/embed-snippet/
COPY packages/features/package.json ./packages/features/
COPY packages/platform/package.json ./packages/platform/
COPY packages/trpc/package.json ./packages/trpc/

# Install dependencies
RUN yarn install --frozen-lockfile

# Copy all source code
COPY . .

# Fix TypeScript configuration for Prisma
RUN echo '{"extends": "./tsconfig.json", "compilerOptions": {"module": "commonjs", "moduleResolution": "node"}}' > packages/prisma/tsconfig.build.json

# Skip the problematic prisma build step and generate directly
RUN cd packages/prisma && npx prisma generate --schema=./schema.prisma

# Set environment variables for build
ENV NEXT_TELEMETRY_DISABLED=1
ENV BUILD_STANDALONE=true
ENV SKIP_BUILD_CHECK=true

# Build only the web app (skip the full turbo build)
RUN cd apps/web && yarn build

# Production image
FROM node:18-alpine AS runner
RUN apk add --no-cache openssl
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Copy standalone build
COPY --from=builder /app/apps/web/.next/standalone ./
COPY --from=builder /app/apps/web/.next/static ./apps/web/.next/static
COPY --from=builder /app/apps/web/public ./apps/web/public
COPY --from=builder /app/packages/prisma ./packages/prisma
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=builder /app/node_modules/@prisma ./node_modules/@prisma

USER nextjs

EXPOSE 3000
ENV PORT=3000

CMD ["node", "apps/web/server.js"]