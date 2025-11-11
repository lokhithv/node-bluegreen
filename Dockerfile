FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --production

COPY . .

# 👇 Add this line — environment color (you’ll override this when building Green)
ENV ENV_COLOR=BLUE

EXPOSE 3000

CMD ["node", "server.js"]
