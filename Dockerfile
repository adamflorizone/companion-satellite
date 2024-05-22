FROM node:18-bullseye

WORKDIR /app
# COPY . /app/

# Rebuild only required files
COPY *yarn* tsconfig*.json package*.json ./
COPY satellite satellite
COPY webui webui

RUN apt-get update && apt-get install -y \
	libusb-1.0-0-dev \
	libudev-dev \
	unzip \
	&& rm -rf /var/lib/apt/lists/*

RUN yarn set version 4.2.2 # restructure for yarn4 workspaces (satellite)
RUN yarn config set httpTimeout 100000 # Newer version of yarn use this!
RUN yarn --frozen-lockfile

# fix: command not found: tsc... Set .bin path
RUN PATH=/app/node_modules/.bin:$PATH; yarn workspaces foreach --all run build
RUN yarn build
RUN yarn workspaces focus 

RUN yarn install # .gitignore: removes node_modules so fresh builds require install
RUN yarn workspaces foreach --all install # .gitignore: node_modules/usb/libusb.gypi: No such file or directory

FROM node:18-bullseye-slim

RUN --mount=type=cache,target=/var/cache/apt \
  apt update && apt install -y  \
	libfontconfig libusb-1.0-0-dev gosu psmisc inotify-tools

WORKDIR /app
COPY --from=0 /app/	/app/
COPY entrypoint.sh ./

# Use root. gosu changes user to node
USER root 

# RUN sed -i "s/! -w \/sys/-w \/sys/" /etc/init.d/udev
ENTRYPOINT ["/app/entrypoint.sh"]
CMD [ "node", "/app/satellite/dist/main.js", "/config/companion-satellite.json" ]

