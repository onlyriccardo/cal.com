FROM node:18-alpine AS builder
RUN apk add --no-cache libc6-compat openssl openssl-dev python3 make g++
WORKDIR /app

# Copy everything
COPY . .

# Install dependencies
RUN yarn install --frozen-lockfile --network-timeout 600000

# Generate Prisma
RUN cd packages/prisma && npx prisma generate || true

# Build the app
ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=production
ENV NODE_OPTIONS="--max-old-space-size=6144"
RUN yarn build

# Production image
FROM node:18-alpine AS runner
RUN apk add --no-cache openssl
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Copy the entire built application
COPY --from=builder /app ./

# The build created everything we need
EXPOSE 3000
ENV PORT=3000

# Start from the web directory
WORKDIR /app/apps/web
CMD ["npm", "start"]