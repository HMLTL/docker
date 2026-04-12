# ── Stage 1: install dependencies ──────────────────────────────
FROM node:22-alpine AS deps

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install --omit=dev && mkdir -p node_modules

# ── Stage 2: runtime ──────────────────────────────────────────
FROM node:22-alpine AS runtime

# non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# copy production deps + source
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# drop privileges
USER appuser

EXPOSE 8080

CMD ["node", "index.js"]
