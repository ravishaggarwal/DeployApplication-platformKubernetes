# appK8Deployment Health — Local Deployment on Docker Desktop Kubernetes

This README documents how to build and run the appK8Deployment Spring Boot application locally on a Mac using Docker Desktop Kubernetes and Helm, with **Horizontal Pod Autoscaler (HPA)** and **PodDisruptionBudget (PDB)** enabled. .


## The Final Output of application when I tested lcoally on my mac via https(SSL) - https://myAppK8Deployment.com.au:8443/health

```bash
curl -vk \
  --resolve myAppK8Deployment.com.au:8443:127.0.0.1 \
  https://myAppK8Deployment.com.au:8443/health
```
```json
ritikamahajan@Hanika-MacBook-Air app-k8-deployment-health % curl -vk \
  --resolve myAppK8Deployment.com.au:8443:127.0.0.1 \
  https://myAppK8Deployment.com.au:8443/health
* Added myAppK8Deployment.com.au:8443:127.0.0.1 to DNS cache
* Hostname myAppK8Deployment.com.au was found in DNS cache
*   Trying 127.0.0.1:8443...
* Connected to myAppK8Deployment.com.au (127.0.0.1) port 8443
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
* [HTTP/2] [1] OPENED stream for https://myAppK8Deployment.com.au:8443/health
* [HTTP/2] [1] [:method: GET]
* [HTTP/2] [1] [:scheme: https]
* [HTTP/2] [1] [:authority: myAppK8Deployment.com.au:8443]
* [HTTP/2] [1] [:path: /health]
* [HTTP/2] [1] [user-agent: curl/8.7.1]
* [HTTP/2] [1] [accept: */*]
> GET /health HTTP/2
> Host: myAppK8Deployment.com.au:8443
> User-Agent: curl/8.7.1
> Accept: */*
> 
* Request completely sent off
< HTTP/2 200 
< date: Tue, 06 Oct 2026 06:15:28 GMT
< content-type: application/json
< strict-transport-security: max-age=31536000; includeSubDomains
< 
* Connection #0 to host myAppK8Deployment.com.au left intact
{"status":"success","version":"1.0.0","message":"application is healthy","environment":"appK8Deployment-localmac"}%  
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
  -keyout local-certs/appK8Deploymenttls.key \
  -out local-certs/appK8Deploymenttls.crt \
  -subj "/CN=myAppK8Deployment.com.au" \
  -addext "subjectAltName=DNS:myAppK8Deployment.com.au"

  kubectl create secret tls appK8Deployment-local-tls \
  --cert=local-certs/appK8Deploymenttls.crt \
  --key=local-certs/appK8Deploymenttls.key \
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
Enable the Ingress and add host and tls secretName: appK8Deployment-local-tls in values-localMac.yaml

NOTE:  
For local docker destop kubernetes setup, Install the ingress-nginx-controller as Ingress controller and 
ssl certs appK8Deployment-local-tls k8 secret will be passed to ingress under values-localMac.yaml for ssh/https connection.

However for the AWS EKS, The installation of the aws-load-balancer-controller as Ingress controller is required, which will be done in actual setup via executing the platform-bootstrap.sh (Via Jenkins platform CD) while creating, provding the SA eks role (LBC_ROLE_AR) which give acces to all AWS service to application pod.

And during application Helm deployment on AWS EKS, pass the ACM_CERTIFICATE_ARN to substitute the ingress certificate arn annotation which is passed as annotation in ingress under values.yaml for AWS EKS.
```

## 3. Build the local Docker image Deploy to Kubernetes using Helm charts:

```bash
helm upgrade --install app-k8-deployment-health \
  ./helm/app-k8-deployment-health \
  --namespace appK8Deployment-localmac \
  --create-namespace \
  -f ./helm/app-k8-deployment-health/values-localMac.yaml \
  --wait \
  --timeout 5m
```

```json
Output:
Release "app-k8-deployment-health" has been upgraded. Happy Helming!
NAME: app-k8-deployment-health
LAST DEPLOYED: Tue Oct  6 17:11:09 2026
NAMESPACE: appK8Deployment-localmac
STATUS: deployed
REVISION: 5
DESCRIPTION: Upgrade complete
TEST SUITE: None
```

```bash
kubectl get ingress -n appK8Deployment-localmac
kubectl describe ingress app-k8-deployment-health -n appK8Deployment-localmac
kubectl get pods,deploy,svc,hpa,pdb -n appK8Deployment-localmac
kubectl rollout status deployment/app-k8-deployment-health -n appK8Deployment-localmac
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
kubectl logs -n appK8Deployment-localmac deployment/app-k8-deployment-health

kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8443:443            
```





