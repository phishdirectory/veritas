FROM ruby:3.4.3-slim AS builder

WORKDIR /rails

LABEL org.opencontainers.image.description="Authentication Package for phish.directory"
LABEL org.opencontainers.image.source="https://github.com/phishdirectory/veritas"

# Install essential build dependencies
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

# Install Node.js and Yarn
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g yarn

# Install specific bundler version
RUN gem install bundler -v 2.5.17

# Copy dependency definitions first for better caching
COPY Gemfile Gemfile.lock .ruby-version ./
COPY package.json yarn.lock ./

# Set bundle config - IMPORTANT: Removed BUNDLE_PATH to use system location
ENV BUNDLE_GEMFILE=Gemfile \
    BUNDLE_JOBS=4 \
    BUNDLE_WITHOUT="development:test"

# Install Ruby and JS dependencies
# Added --no-cache to ensure gems are properly installed
RUN bundle config set --local without 'development test' && \
    bundle install --no-cache && \
    yarn install --frozen-lockfile

# Add source code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompile assets without requiring RAILS_MASTER_KEY
RUN SECRET_KEY_BASE_DUMMY=1 RAILS_ENV=production ./bin/rails assets:precompile

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
    libyaml-0-2 \
    curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js for runtime (needed for some Rails assets)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set editor for credentials
ENV EDITOR=nano

WORKDIR /rails

# Copy gems from builder stage - IMPORTANT: Copy the entire gem installation
COPY --from=builder /usr/local/lib/ruby/gems/ /usr/local/lib/ruby/gems/
COPY --from=builder /usr/local/bundle/ /usr/local/bundle/

# Copy node_modules from builder
COPY --from=builder /rails/node_modules /rails/node_modules

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

# Create an entrypoint script to verify gem installation
RUN echo '#!/bin/bash\necho "Verifying gem installation..."\nbundle check || bundle install\nexec "$@"' > /rails/bin/docker-entrypoint && \
    chmod +x /rails/bin/docker-entrypoint

# Set entry point and default command
ENTRYPOINT ["/rails/bin/docker-entrypoint"]
EXPOSE 3000
CMD ["./bin/thrust", "./bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]
