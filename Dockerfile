# -----------------------------------------------------------------------
# builder stage
# -----------------------------------------------------------------------
FROM rust:1.97.1 AS builder

# Let's switch our working directory to `app` (equivalent to `cd app`)
# The `app` folder will be created for us by Docker in case it does not
# exist already.
WORKDIR /app

# install required dependencies
RUN apt update && apt install lld clang -y

# copy all files from our working environment to our Docker image
COPY . .

# Let's build our binary!
# We'll use the release profile to make it fast
ENV SQLX_OFFLINE=true
RUN cargo build --release


# -----------------------------------------------------------------------
# runtime stage
# -----------------------------------------------------------------------
FROM debian:bookworm-slim AS runtime
WORKDIR /app
# Install OpenSSL - it is dynamically linked by some of our dependencies
# Install ca-certificates - it is needed to verify TLS certificates
# when establishing HTTPS connections
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends openssl ca-certificates \
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# copy the compiled binary from the builder environment
# to our runtime environment
COPY --from=builder /app/target/release/zero2prod zero2prod

# we need the configuration file at runtime
COPY configuration configuration
ENV APP_ENVIRONMENT=production

# when 'docker run' is executed, launch the binary
ENTRYPOINT [ "./zero2prod" ]
