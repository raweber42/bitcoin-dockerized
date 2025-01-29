FROM debian:bookworm-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates git gnupg python3 wget

ARG checkout
ARG BITCOIN_URL=https://bitcoincore.org/bin/bitcoin-core-$checkout/bitcoin-$checkout-x86_64-linux-gnu.tar.gz

ARG SIGS_CLONE_DIR="/verify/guix.sigs/"
ARG BITCOIN_CORE_DIR="/verify/bitcoin/"
ARG VERIFY_SCRIPT_LOCATION="/verify/bitcoin/contrib/verify-binaries/verify.py"
ARG MIN_REQUIRED_GOOD_SIGS=6

RUN mkdir -p /verify
RUN git clone "https://github.com/getlipa/guix.sigs.git" /verify/guix.sigs
RUN git clone "https://github.com/getlipa/bitcoin.git" /verify/bitcoin

RUN set -ex \
    && cd /verify \
	&& wget -qO bitcoin.tar.gz "$BITCOIN_URL" \
    && gpg --import "${SIGS_CLONE_DIR}"builder-keys/* \
    && chmod +x ${VERIFY_SCRIPT_LOCATION} \
    && python3 ${VERIFY_SCRIPT_LOCATION} \
        --min-good-sigs ${MIN_REQUIRED_GOOD_SIGS} pub "${checkout}-x86_64-linux" \
	&& tar -xzvf bitcoin.tar.gz -C /usr/local --strip-components=1 --exclude=*-qt
    
FROM debian:bookworm-slim
COPY --from=builder /usr/local/bin/bitcoind /usr/local/bin/bitcoin-cli /usr/local/bin/
RUN groupadd -r -g 101 bitcoin && useradd -r -u 999 -m -g bitcoin bitcoin

ARG BITCOIN_DATA=/home/bitcoin/.bitcoin

VOLUME $BITCOIN_DATA

USER bitcoin

EXPOSE 8332 8333 18332 18333 18443 18444 38333 38332

ENTRYPOINT ["bitcoind"]
