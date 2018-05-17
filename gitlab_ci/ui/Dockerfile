FROM python:3.6.0-alpine

ARG APP_HOME=/app

RUN mkdir $APP_HOME
WORKDIR $APP_HOME
COPY ./ui $APP_HOME
COPY requirements.txt $APP_HOME

RUN echo http://mirror.yandex.ru/mirrors/alpine/v3.5/main > /etc/apk/repositories; \
    echo http://mirror.yandex.ru/mirrors/alpine/v3.5/community >> /etc/apk/repositories
RUN apk --no-cache add gcc musl-dev python3-dev
RUN pip install --upgrade pip && pip install -r requirements.txt

ENV MONGO mongo
ENV MONGO_PORT 27017
ENV FLASK_APP=$APP_HOME/ui.py

ENTRYPOINT ["gunicorn", "ui:app", "-b", "0.0.0.0"]
