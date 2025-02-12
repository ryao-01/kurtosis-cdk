FROM debian:stable-slim as builder

# WARNING (DL3008): Pin versions in apt get install.
# hadolint ignore=DL3008
RUN apt-get update \
  && apt-get --yes upgrade \
  && apt-get install --yes --no-install-recommends libssl-dev ca-certificates jq git curl make grep \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  # Pull and install Foundry
  && curl --silent --location --proto "=https" https://foundry.paradigm.xyz | bash \
  && /root/.foundry/bin/foundryup \
  && cp /root/.foundry/bin/* /usr/local/bin \
  # Smart contract stuff (deploy before polymarket)
  && git clone --branch main https://github.com/ryao-01/proxy-factories.git \
  # Polymarket stuff
  && git clone --branch main https://github.com/ryao-01/ctf-exchange.git \
  # Pull kurtosis-cdk package from my repo.
  # && git clone --branch feat/antithesis-integration https://github.com/leovct/kurtosis-cdk \
  # && git clone --branch v0.2.29 https://github.com/0xPolygon/kurtosis-cdk.git \
  && git clone --branch main https://github.com/ryao-01/kurtosis-cdk.git \
  # Pull kurtosis-cdk dependencies.
  # The package has other dependencies (blockscout, prometheus and grafana) but they shouldn't be used when testing the package with Antithesis.
  && git clone --branch 4.4.0 https://github.com/ethpandaops/ethereum-package \
  && git clone --branch 1.2.0 https://github.com/ethpandaops/optimism-package \
  # Make the kurtosis-cdk package reference locally pulled dependencies.
  # This also includes smart contract stuff and Polymarket stuff. 
  && sed -i '$ a\\nreplace:\n    github.com/ryao-01/proxy-factories: ../proxy-factories\n    github.com/ryao-01/ctf-exchange: ../ctf-exchange\n    github.com/ethpandaops/ethereum-package: ../ethereum-package\n    github.com/ethpandaops/optimism-package: ../optimism-package\n    github.com/kurtosis-tech/redis-package: ../redis-package\n    github.com/kurtosis-tech/postgres-package: ../postgres-package\n    github.com/bharath-123/db-adminer-package: ../db-adminer-package\n    github.com/kurtosis-tech/prometheus-package: ../prometheus-package' /kurtosis-cdk/kurtosis.yml \
  # Pull ethereum package dependencies.
  && git clone --branch main https://github.com/kurtosis-tech/prometheus-package \
  && git clone --branch main https://github.com/kurtosis-tech/postgres-package \
  && git clone --branch main https://github.com/bharath-123/db-adminer-package \
  && git clone --branch main https://github.com/kurtosis-tech/redis-package \
  # More dependencies
  && git clone --branch main https://github.com/0xPolygon/cdk-data-availability.git \
  # Make the ethereum package reference locally pulled dependencies.
  && sed -i '$ a\\nreplace:\n    github.com/kurtosis-tech/prometheus-package: ../prometheus-package\n    github.com/kurtosis-tech/postgres-package: ../postgres-package\n    github.com/bharath-123/db-adminer-package: ../db-adminer-package\n    github.com/kurtosis-tech/redis-package: ../redis-package' /ethereum-package/kurtosis.yml \
  # Pull optimism package dependencies.
  # It relies on the ethereum package which is already pulled.
  # && cat /kurtosis-cdk/kurtosis.yml \
  && sed -i '$ a\\nreplace:\n    github.com/ethpandaops/ethereum-package: ../ethereum-package' /optimism-package/kurtosis.yml

FROM debian:stable-slim
LABEL author="richard.yao@antithesis.com"
LABEL description="Antithesis config image for kurtosis-cdk"

# Install Node.js and npm in the final image 
RUN apt-get update && apt-get install -y nodejs npm

COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /kurtosis-cdk /kurtosis-cdk
COPY --from=builder /proxy-factories /proxy-factories
COPY --from=builder /ctf-exchange /ctf-exchange
COPY --from=builder /ethereum-package /ethereum-package
COPY --from=builder /prometheus-package /prometheus-package
COPY --from=builder /postgres-package /postgres-package
COPY --from=builder /db-adminer-package /db-adminer-package
COPY --from=builder /redis-package /redis-package
COPY --from=builder /optimism-package /optimism-package

WORKDIR /kurtosis-cdk
# Install ethers.js and other npm dependencies 
RUN npm install ethers 
# Optional verification steps (add these for build-time checks) 
RUN node -v 
RUN npm -v 
RUN node -e "try { require('ethers'); console.log('ethers.js installed successfully'); } catch (e) { console.error('ethers.js installation failed', e); process.exit(1); }"
