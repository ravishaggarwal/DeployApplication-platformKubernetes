# AusPost Health — Local Deployment on Docker Desktop Kubernetes

This README documents how to build and run the AusPost Spring Boot application locally on a Mac using Docker Desktop Kubernetes and Helm, with **Horizontal Pod Autoscaler (HPA)** and **PodDisruptionBudget (PDB)** enabled. .

Check the cluster and tools:

```bash
kubectl config use-context docker-desktop
kubectl get nodes
helm version
docker version
```

## 1. Build and test the Spring Boot application

```
APP_VERSION=1.0.0 ./gradlew clean test bootJar
```

```bash
./gradlew componentTest
```

```bash
ls -lh build/libs/auspost-health-1.0.0.jar
```

## 2. Build the local Docker image

```bash
cd ..
docker build \
  --build-arg APP_VERSION=1.0.0 \
  -f container/Dockerfile \
  -t auspost-health:1.0.0 \
  .
docker images auspost-health
```

## 3. Build the local Docker image Deploy to Kubernetes using Helm charts:

```bash
helm upgrade --install auspost-health \
  ./helm/auspost-health \
  --namespace auspost-localMac \
  --create-namespace \
  -f ./helm/auspost-health/values-localMac.yaml \
  --wait \
  --timeout 5m
```

```bash
kubectl get pods,deploy,svc,hpa,pdb -n auspost-localMac
kubectl rollout status deployment/auspost-health -n auspost-localMac
kubectl logs -n auspost-localMac deployment/auspost-health
```

## 4. Acceess the application K8 Pod

```bash
kubectl exec -it -n auspost-localMac deployment/auspost-health -- /bin/sh
```

## 5. The Applicaiton Actuator endpoints Output of application when I tested lcoally on my mac.

```bash
curl http://localhost:8080/health
curl http://localhost:8080/actuator/health
curl http://localhost:8080/actuator/health/readiness
curl http://localhost:8080/actuator/health/liveness
exit
```

## 6. The Output of application when I tested lcoally on my mac.

```json
{
  "status": "success",
  "message": "application is healthy",
  "version": "1.0.0",
  "environment": "auspost-localMac"
}
```

