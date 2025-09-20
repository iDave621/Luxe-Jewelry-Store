# Setting Up HTTPS for Nexus Repository Manager

This guide provides step-by-step instructions to configure Nexus Repository Manager with HTTPS.

## Prerequisites

- Nexus Repository Manager installed and running
- SSH access to the Nexus server
- `keytool` utility (included with Java)

## 1. Generate SSL Certificates

Copy the `setup-nexus-ssl.sh` script to your Nexus server and run:

```bash
# First make the script executable
chmod +x setup-nexus-ssl.sh

# Run the script as the nexus user
sudo -u nexus ./setup-nexus-ssl.sh
```

## 2. Configure Nexus for HTTPS

1. Copy the `nexus-jetty-https.xml` file to the Nexus configuration directory:

```bash
sudo cp nexus-jetty-https.xml /opt/nexus/etc/jetty/
```

2. Edit the Nexus properties file:

```bash
sudo vi /opt/nexus/etc/nexus-default.properties
```

3. Update the `application-port-ssl` property:

```properties
# Jetty section
application-port=8081
application-host=0.0.0.0
nexus-args=${jetty.etc}/jetty.xml,${jetty.etc}/jetty-http.xml,${jetty.etc}/jetty-requestlog.xml,${jetty.etc}/nexus-jetty-https.xml
application-port-ssl=8443
```

4. Restart Nexus:

```bash
sudo systemctl restart nexus
```

## 3. Configure Docker Repository for HTTPS

1. Log into Nexus web UI at https://192.168.1.117:8443/
2. Go to Settings > Repositories
3. Click on "docker-hosted" repository
4. Make the following changes:
   - Under "HTTP", disable HTTP or leave it enabled for compatibility
   - Under "HTTPS", check "Enable HTTPS" and set port to 8082
   - Click "Save"

## 4. Configure Jenkins to Use HTTPS

1. Get the Nexus certificate:

```bash
sudo cp /opt/nexus/etc/ssl/nexus.pem /tmp/nexus.pem
sudo chmod 644 /tmp/nexus.pem
```

2. Copy the certificate to your Jenkins server:

```bash
scp /tmp/nexus.pem jenkins-server:/tmp/
```

3. Add the certificate to Jenkins Java truststore:

```bash
sudo keytool -import -alias nexus -keystore $JAVA_HOME/lib/security/cacerts -file /tmp/nexus.pem
```

4. Add the certificate to Docker:

```bash
sudo mkdir -p /etc/docker/certs.d/192.168.1.117:8082
sudo cp /tmp/nexus.pem /etc/docker/certs.d/192.168.1.117:8082/ca.crt
sudo systemctl restart docker
```

## 5. Update the Jenkinsfile

Update the `NEXUS_DOCKER_REGISTRY` variable in your Jenkinsfile to use HTTPS:

```groovy
NEXUS_DOCKER_REGISTRY = "192.168.1.117:8082"
```

The Docker client will now use HTTPS to connect to this registry.

## Verification

Test the HTTPS connection:

```bash
curl -v https://192.168.1.117:8443/service/rest/v1/status
```

Test Docker push:

```bash
docker login 192.168.1.117:8082
docker tag my-image:latest 192.168.1.117:8082/my-image:latest
docker push 192.168.1.117:8082/my-image:latest
```

## Troubleshooting

If Docker still gives certificate errors, verify that:
1. The certificate is properly installed in `/etc/docker/certs.d/192.168.1.117:8082/ca.crt`
2. The certificate's CN matches the hostname (192.168.1.117)
3. Docker has been restarted after certificate installation
