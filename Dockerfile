FROM ruby:3.2.4-alpine

WORKDIR /app

COPY . .

RUN bundle install

CMD ["bash"]