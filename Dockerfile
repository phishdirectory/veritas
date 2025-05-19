FROM ruby:3.4.3-slim AS builder

WORKDIR /rails

# Install essential build dependencies including unzip for bun
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    pkg-config \
    libpq-dev \
    unzip \
    libffi-dev \
    libyaml-dev \
    git \
    libvips-dev \
    libmagickwand-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
    
# Install bun for node packages
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

# Install specific bundler version
RUN gem install bundler -v 2.5.17

# Copy dependency definitions first for better caching
COPY Gemfile Gemfile.lock .ruby-version ./
COPY package.json bun.lock ./

# Set bundle config
ENV BUNDLE_GEMFILE=Gemfile \
    BUNDLE_JOBS=4 \
    BUNDLE_PATH=/usr/local/bundle

# Install Ruby and JS dependencies
RUN bundle install && \
    bun install

# Add source code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompile assets without requiring RAILS_MASTER_KEY
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# Set permissions on executables
RUN chmod +x bin/rails bin/* 

# Create a clean runtime image
FROM ruby:3.4.3-slim

# Install runtime dependencies only
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    postgresql-client \
    nano \
    poppler-utils \
    libpq5 \
    libvips42 \
    libffi8 \
    libyaml-0-2 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set editor for credentials
ENV EDITOR=nano

WORKDIR /rails

# Copy gems from builder stage
COPY --from=builder /usr/local/bundle /usr/local/bundle

# Copy bun from builder
COPY --from=builder /root/.bun /root/.bun
ENV PATH="/root/.bun/bin:${PATH}"

# Copy application from builder
COPY --from=builder /rails /rails

# Handle Rubocop config symlinks
RUN ln -sf /rails/.rubocop.yml ~/.rubocop.yml && \
    ln -sf /rails/.rubocop_todo.yml ~/.rubocop_todo.yml

# Set application environment
ENV BUNDLE_GEMFILE=Gemfile \
    RAILS_ENV=production \
    RAILS_SERVE_STATIC_FILES=true \
    RAILS_LOG_TO_STDOUT=true

# Set entry point and default command
ENTRYPOINT ["/rails/bin/docker-entrypoint"]
EXPOSE 80
CMD ["./bin/thrust", "./bin/rails", "server"]