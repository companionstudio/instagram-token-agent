FROM ruby:2.6.5

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
RUN gem install bundler && bundle install

COPY . .

COPY docker/ruby/entrypoint.sh /entrypoint.sh
RUN chmod +x "/entrypoint.sh"

ENTRYPOINT ["/entrypoint.sh"]
