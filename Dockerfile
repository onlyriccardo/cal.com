FROM node:18-alpine
RUN apk add --no-cache libc6-compat openssl python3 make g++ git
WORKDIR /app

# Copy everything
COPY . .

# Remove yarn lock and use npm
RUN rm -f yarn.lock
RUN npm install --legacy-peer-deps

# Generate Prisma
RUN cd packages/prisma && npx prisma generate

# Build
ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=production
ENV NODE_OPTIONS="--max-old-space-size=6144"

WORKDIR /app/apps/web
RUN npm run build

EXPOSE 3000
CMD ["npm", "start"]