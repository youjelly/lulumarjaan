FROM mongo:7.0

# Set default port
EXPOSE 27017

# Add custom configuration if needed
COPY mongod.conf.example /etc/mongod.conf.example

# Set data directory
VOLUME ["/data/db"]

# Use default MongoDB command
CMD ["mongod"]