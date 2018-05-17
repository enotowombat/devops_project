FROM python:3.6.0-alpine

ARG APP_HOME=/app

RUN mkdir $APP_HOME
WORKDIR $APP_HOME
COPY ./crawler $APP_HOME
COPY requirements.txt $APP_HOME

RUN echo http://mirror.yandex.ru/mirrors/alpine/v3.5/main > /etc/apk/repositories; \
    echo http://mirror.yandex.ru/mirrors/alpine/v3.5/community >> /etc/apk/repositories
RUN apk --no-cache add gcc musl-dev python3-dev bash
RUN pip install --upgrade pip && pip install -r requirements.txt

ENV MONGO mongo
ENV MONGO_PORT 27017
ENV RMQ_HOST rabbitmq
ENV RMQ_QUEUE rabbit
ENV RMQ_USERNAME guest
ENV RMQ_PASSWORD guest
ENV CHECK_INTERVAL 60
ENV EXCLUDE_URLS .*github.com

ENTRYPOINT ["python3", "-u", "crawler.py", "https://vitkhab.github.io/search_engine_test_site"]
