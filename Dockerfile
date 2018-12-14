FROM python:3
RUN pip install "devpi-server>=4.8,<5.0" "devpi-web>=3.5,<4.0" "devpi-client>=4.2,<5.0"
VOLUME /mnt
EXPOSE 3141
ADD run.sh /
CMD ["/run.sh"]
