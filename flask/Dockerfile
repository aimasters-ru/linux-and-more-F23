FROM ubuntu:20.04
MAINTAINER Artem
RUN apt-get update -y && apt-get install -y python3-pip
ADD . /flask-app
WORKDIR /flask-app
RUN pip3 install -r requirements.txt
ENTRYPOINT ["python3", "flask-app.py"]
