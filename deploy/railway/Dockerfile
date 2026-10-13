# Public web demo on Railway: the built page, the demo prover (dummy cards only) and the relay, on one port.
# Build context = the directory staged by deploy/railway/stage.sh, which adds the files that are not in git:
#   circuits/build/{jpki_age_region_js/, vkey.json, dummy-ca.pem, persona-*.pem}
#   app/verifier-demo/dist/  (npm run build)
# The 0.9 GB zkey is not in the image: it is on the volume mounted at /data.
# The dummy CA and persona keys are test keys for dummy cards; no real card data is involved.
# trixie: the rapidsnark v0.0.8 binary needs GLIBCXX_3.4.32 (bookworm has 3.4.30)
FROM node:22-trixie-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends python3 python3-cryptography curl unzip ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# rapidsnark prover (iden3 release)
RUN curl -fsSL -o /tmp/rs.zip https://github.com/iden3/rapidsnark/releases/download/v0.0.8/rapidsnark-linux-x86_64-v0.0.8.zip \
 && unzip -q /tmp/rs.zip -d /opt && rm /tmp/rs.zip \
 && ln -s "$(ls -d /opt/rapidsnark-*/bin/prover)" /usr/local/bin/rapidsnark
ENV RAPIDSNARK=/usr/local/bin/rapidsnark

WORKDIR /app
# node deps used by circuits/scripts (export_solana.cjs: circomlibjs) and make-claim.sh (sdk: @solana/web3.js)
RUN mkdir -p circuits && cd circuits && npm install --no-save --no-package-lock --omit=dev circomlibjs@0.1.7
COPY sdk/package.json sdk/package-lock.json sdk/
RUN cd sdk && npm ci --omit=dev

RUN mkdir -p circuits/build && ln -s /data/jpki_age_region.zkey circuits/build/jpki_age_region.zkey
COPY circuits/build/jpki_age_region_js circuits/build/jpki_age_region_js
COPY circuits/build/vkey.json circuits/build/dummy-ca.pem circuits/build/
COPY circuits/build/persona-tokyo20.pem circuits/build/persona-osaka40.pem circuits/build/persona-tokyo17.pem circuits/build/
COPY circuits/scripts circuits/scripts
COPY sdk/src sdk/src
COPY app/verifier-demo/server app/verifier-demo/server
COPY app/verifier-demo/dist app/verifier-demo/dist

# Railway's edge puts the client address in X-Real-IP and injects PORT at runtime.
ENV PUBLIC=1 HOST=0.0.0.0 PORT=8080 IP_HEADER=x-real-ip PYTHON=python3
EXPOSE 8080
CMD ["node", "app/verifier-demo/server/mock-prover.mjs"]
