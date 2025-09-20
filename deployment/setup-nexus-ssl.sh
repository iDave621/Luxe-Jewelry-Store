#!/bin/bash
# Script to generate self-signed certificates for Nexus

# Set variables
NEXUS_HOST="192.168.1.117"
NEXUS_SSL_DIR="/opt/nexus/etc/ssl"
KEYSTORE_PASSWORD="nexus123"  # Change this to a secure password

# Create directory for certificates
mkdir -p $NEXUS_SSL_DIR

# Generate a keystore with a self-signed certificate
keytool -genkeypair -keystore $NEXUS_SSL_DIR/keystore.jks -storepass $KEYSTORE_PASSWORD -keypass $KEYSTORE_PASSWORD \
  -alias jetty -keyalg RSA -keysize 2048 -validity 5000 \
  -dname "CN=${NEXUS_HOST}, OU=DevOps, O=LuxeJewelry, L=YourCity, ST=YourState, C=US" \
  -ext "SAN=DNS:${NEXUS_HOST},IP:${NEXUS_HOST}"

# Export the certificate
keytool -exportcert -keystore $NEXUS_SSL_DIR/keystore.jks -storepass $KEYSTORE_PASSWORD \
  -alias jetty -file $NEXUS_SSL_DIR/nexus.cer

# Create truststore with the exported certificate
keytool -importcert -keystore $NEXUS_SSL_DIR/truststore.jks -storepass $KEYSTORE_PASSWORD \
  -alias jetty -file $NEXUS_SSL_DIR/nexus.cer -noprompt

# Export the certificate in PEM format for Docker clients
keytool -exportcert -keystore $NEXUS_SSL_DIR/keystore.jks -storepass $KEYSTORE_PASSWORD \
  -alias jetty -rfc -file $NEXUS_SSL_DIR/nexus.pem

# Set correct permissions
chmod 644 $NEXUS_SSL_DIR/nexus.cer $NEXUS_SSL_DIR/nexus.pem
chmod 640 $NEXUS_SSL_DIR/keystore.jks $NEXUS_SSL_DIR/truststore.jks

echo "Self-signed certificates generated in $NEXUS_SSL_DIR"
echo "Remember to copy nexus.pem to Docker clients and add it to their trusted certificates"
