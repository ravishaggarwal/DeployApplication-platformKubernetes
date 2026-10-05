# AusPost Health — Local Deployment on Docker Desktop Kubernetes

This README documents how to build and run the AusPost Spring Boot application locally on a Mac using Docker Desktop Kubernetes and Helm, with **Horizontal Pod Autoscaler (HPA)** and **PodDisruptionBudget (PDB)** enabled. .


## The Final Output of application when I tested lcoally on my mac via https(SSL) - https://myauspost.com.au:8443/health

```bash
curl -vk \
  --resolve myauspost.com.au:8443:127.0.0.1 \
  https://myauspost.com.au:8443/health
```
```json
ritikamahajan@Hanika-MacBook-Air auspost-health % curl -vk \
  --resolve myauspost.com.au:8443:127.0.0.1 \
  https://myauspost.com.au:8443/health
* Added myauspost.com.au:8443:127.0.0.1 to DNS cache
* Hostname myauspost.com.au was found in DNS cache
*   Trying 127.0.0.1:8443...
* Connected to myauspost.com.au (127.0.0.1) port 8443
* ALPN: curl offers h2,http/1.1
* (304) (OUT), TLS handshake, Client hello (1):
* (304) (IN), TLS handshake, Server hello (2):
* (304) (IN), TLS handshake, Unknown (8):
* (304) (IN), TLS handshake, Certificate (11):
* (304) (IN), TLS handshake, CERT verify (15):
* (304) (IN), TLS handshake, Finished (20):
* (304) (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / AEAD-AES256-GCM-SHA384 / [blank] / UNDEF
* ALPN: server accepted h2
* Server certificate:
*  subject: O=Acme Co; CN=Kubernetes Ingress Controller Fake Certificate
*  start date: Oct  4 04:20:47 2026 GMT
*  expire date: Oct  4 04:20:47 2027 GMT
*  issuer: O=Acme Co; CN=Kubernetes Ingress Controller Fake Certificate
*  SSL certificate verify result: unable to get local issuer certificate (20), continuing anyway.
* using HTTP/2
* [HTTP/2] [1] OPENED stream for https://myauspost.com.au:8443/health
* [HTTP/2] [1] [:method: GET]
* [HTTP/2] [1] [:scheme: https]
* [HTTP/2] [1] [:authority: myauspost.com.au:8443]
* [HTTP/2] [1] [:path: /health]
* [HTTP/2] [1] [user-agent: curl/8.7.1]
* [HTTP/2] [1] [accept: */*]
> GET /health HTTP/2
> Host: myauspost.com.au:8443
> User-Agent: curl/8.7.1
> Accept: */*
> 
* Request completely sent off
< HTTP/2 200 
< content-type: application/json
< strict-transport-security: max-age=31536000; includeSubDomains
< 
* Connection #0 to host myauspost.com.au left intact
{"status":"success","version":"1.0.0","message":"application is healthy","environment":"auspost-localmac"}%                                                                                                    MacBook-Air auspost-health %
```

## Pre Requisites to Achieve this:

Check the cluster and tools:

```bash
kubectl config use-context docker-desktop
kubectl get nodes
helm version
docker version
```

## 1. Create ssl certificate and K8 secret with that certificate & Installed the NGNIX Controller for local desktop kubernetes setup.

```bash
mkdir -p local-certs

openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout local-certs/ausposttls.key \
  -out local-certs/ausposttls.crt \
  -subj "/CN=myauspost.com.au" \
  -addext "subjectAltName=DNS:myauspost.com.au"

  kubectl create secret tls auspost-local-tls \
  --cert=local-certs/ausposttls.crt \
  --key=local-certs/ausposttls.key \
  -n localmac

helm repo add ingress-nginx \
  https://kubernetes.github.io/ingress-nginx

helm repo update

helm upgrade --install ingress-nginx \
  ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer

  kubectl rollout status deployment/ingress-nginx-controller \
  -n ingress-nginx \
  --timeout=180s
```

## 2. Update the values-localmac.yaml, Enable the Ingress.

```bash
Enable the Ingress and add host and tls secretName: auspost-local-tls in values-localMac.yaml

NOTE:  
For local docker destop kubernetes setup, Install the ingress-nginx-controller as Ingress controller and 
ssl certs auspost-local-tls k8 secret will be passed to ingress under values-localMac.yaml for ssh/https connection.

However for the AWS EKS, The installation of the aws-load-balancer-controller as Ingress controller is required, which will be done in actual setup via executing the platform-bootstrap.sh (Via Jenkins platform CD) while creating, provding the SA eks role (LBC_ROLE_AR) which give acces to all AWS service to application pod.

And during application Helm deployment on AWS EKS, pass the ACM_CERTIFICATE_ARN to substitute the ingress certificate arn annotation which is passed as annotation in ingress under values.yaml for AWS EKS.
```

## 3. Build the local Docker image Deploy to Kubernetes using Helm charts:

```bash
helm upgrade --install auspost-health \
  ./helm/auspost-health \
  --namespace auspost-localmac \
  --create-namespace \
  -f ./helm/auspost-health/values-localMac.yaml \
  --wait \
  --timeout 5m
```

```json
Output:
Release "auspost-health" has been upgraded. Happy Helming!
NAME: auspost-health
NAMESPACE: auspost-localmac
STATUS: deployed
REVISION: 2
DESCRIPTION: Upgrade complete
```

```bash
kubectl get ingress -n auspost-localmac
kubectl describe ingress auspost-health -n auspost-localmac
kubectl get pods,deploy,svc,hpa,pdb -n auspost-localmac
kubectl rollout status deployment/auspost-health -n auspost-localmac
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
kubectl logs -n auspost-localmac deployment/auspost-health

kubectl port-forward \                   
  -n ingress-nginx \     
  svc/ingress-nginx-controller \
  8443:443            
```





