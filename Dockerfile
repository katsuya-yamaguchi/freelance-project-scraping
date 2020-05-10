FROM ruby:2.7.1

ENV APP_ROOT /freelance-project-scraping
WORKDIR ${APP_ROOT}

RUN apt-get update

COPY ./Gemfile ${APP_ROOT}
COPY ./Gemfile.lock ${APP_ROOT}

RUN echo 'gem: --no-document' >> ~/.gemrc && \
    cp ~/.gemrc /etc/gemrc && \
    bundle config --global jobs 4 && \
    bundle install

COPY . ${APP_ROOT}/
