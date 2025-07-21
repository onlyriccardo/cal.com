FROM node:18-alpine
RUN apk add --no-cache libc6-compat openssl python3 make g++ git
WORKDIR /app

# Enable corepack for Yarn 3
RUN corepack enable

# Copy everything
COPY . .

# Install dependencies using the correct yarn version
RUN yarn install --immutable

# Generate Prisma
RUN cd packages/prisma && npx prisma generate --schema=./schema.prisma

# Build only the web app
ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=production
ENV NODE_OPTIONS="--max-old-space-size=6144"

WORKDIR /app/apps/web
RUN yarn build

# Production stage
EXPOSE 3000
ENV PORT=3000

CMD ["yarn", "start"]