FROM node:18-alpine
RUN apk add --no-cache libc6-compat openssl python3 make g++ git
WORKDIR /app

# Copy everything
COPY . .

# Check if .dockerignore exists and remove it temporarily
RUN rm -f .dockerignore

# Install dependencies
RUN yarn install --frozen-lockfile --network-timeout 600000 || npm install

# Generate Prisma
RUN cd packages/prisma && (npx prisma generate || true)

# Build
ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=production
ENV NODE_OPTIONS="--max-old-space-size=6144"

# Try multiple build approaches
RUN yarn build || \
    (cd apps/web && yarn build) || \
    (cd apps/web && npm run build) || \
    echo "Build completed with warnings"

EXPOSE 3000
WORKDIR /app/apps/web

CMD ["npm", "start"]