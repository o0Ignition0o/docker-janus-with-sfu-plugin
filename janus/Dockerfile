FROM debian:latest

RUN apt update && apt install -y git
ADD ./install.sh /
RUN chmod +x /install.sh
RUN /install.sh

# Disable a security warning at startup 
RUN pip install service_identity

ADD ./start.sh /
RUN chmod +x /start.sh

# Had a rough time when I tried to run janus with the plugin and no config file, or when the file was empty
RUN echo '[general] \n' > /opt/janus/etc/janus/janus.plugin.sfu.cfg

CMD /start.sh