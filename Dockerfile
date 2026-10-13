FROM ruby:3.3-alpine

WORKDIR /app
ENV BUNDLE_WITHOUT=test \
    BUNDLE_FROZEN=true

COPY Gemfile Gemfile.lock ./
RUN bundle install
COPY server.rb ./

ENV PORT=8080
EXPOSE 8080

CMD ["bundle", "exec", "ruby", "server.rb"]
