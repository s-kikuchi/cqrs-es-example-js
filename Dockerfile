FROM node:20-alpine AS base

FROM base AS builder

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable

RUN apk add --no-cache libc6-compat
WORKDIR /app

COPY . /app

RUN pnpm install -g turbo && pnpm install && pnpm prisma:generate && pnpm build

FROM base AS runner
WORKDIR /app/packages/bootstrap

RUN apk add --no-cache libc6-compat
RUN apk add --no-cache openssl3
RUN apk update

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nodejs

COPY --from=builder --chown=nodejs:nodejs /app/node_modules /app/node_modules
COPY --from=builder --chown=nodejs:nodejs /app/package.json /app/package.json

COPY --from=builder --chown=nodejs:nodejs /app/packages/bootstrap/node_modules /app/packages/bootstrap/node_modules
COPY --from=builder --chown=nodejs:nodejs /app/packages/bootstrap/dist /app/packages/bootstrap/dist
COPY --from=builder --chown=nodejs:nodejs /app/packages/bootstrap/package.json /app/packages/bootstrap/package.json

COPY --from=builder --chown=nodejs:nodejs /app/packages/command/domain/node_modules /app/packages/command/domain/node_modules
COPY --from=builder --chown=nodejs:nodejs /app/packages/command/domain/dist /app/packages/command/domain/dist
COPY --from=builder --chown=nodejs:nodejs /app/packages/command/domain/package.json /app/packages/command/domain/package.json

COPY --from=builder --chown=nodejs:nodejs /app/packages/command/interface-adaptor-if/node_modules /app/packages/command/interface-adaptor-if/node_modules
COPY --from=builder --chown=nodejs:nodejs /app/packages/command/interface-adaptor-if/dist /app/packages/command/interface-adaptor-if/dist
COPY --from=builder --chown=nodejs:nodejs /app/packages/command/interface-adaptor-if/package.json /app/packages/command/interface-adaptor-if/package.json

COPY --from=builder --chown=nodejs:nodejs /app/packages/command/interface-adaptor-impl/node_modules /app/packages/command/interface-adaptor-impl/node_modules
COPY --from=builder --chown=nodejs:nodejs /app/packages/command/interface-adaptor-impl/dist /app/packages/command/interface-adaptor-impl/dist
COPY --from=builder --chown=nodejs:nodejs /app/packages/command/interface-adaptor-impl/package.json /app/packages/command/interface-adaptor-impl/package.json

COPY --from=builder --chown=nodejs:nodejs /app/packages/command/use-case/node_modules /app/packages/command/use-case/node_modules
COPY --from=builder --chown=nodejs:nodejs /app/packages/command/use-case/dist /app/packages/command/use-case/dist
COPY --from=builder --chown=nodejs:nodejs /app/packages/command/use-case/package.json /app/packages/command/use-case/package.json

COPY --from=builder --chown=nodejs:nodejs /app/packages/rmu/node_modules /app/packages/rmu/node_modules
COPY --from=builder --chown=nodejs:nodejs /app/packages/rmu/dist /app/packages/rmu/dist
COPY --from=builder --chown=nodejs:nodejs /app/packages/rmu/package.json /app/packages/rmu/package.json

COPY --from=builder --chown=nodejs:nodejs /app/packages/query/interface-adaptor/node_modules /app/packages/query/interface-adaptor/node_modules
COPY --from=builder --chown=nodejs:nodejs /app/packages/query/interface-adaptor/dist /app/packages/query/interface-adaptor/dist
COPY --from=builder --chown=nodejs:nodejs /app/packages/query/interface-adaptor/package.json /app/packages/query/interface-adaptor/package.json

USER nodejs
EXPOSE 3000

ENTRYPOINT ["node", "./dist/index.js"]
