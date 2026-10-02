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

Optional component tests:

```bash
./gradlew componentTest
```

Confirm the generated JAR:

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

Docker Desktop Kubernetes can normally use images built in Docker Desktop's image store directly. The local Helm values below set `image.pullPolicy: Never`, so Kubernetes will not try to pull from JFrog.



## 3. Build the local Docker image Deploy to Kubernetes using Helm charts:

```bash
helm upgrade --install auspost-health \
  ./helm/auspost-health \
  --namespace auspost-local \
  --create-namespace \
  -f ./helm/auspost-health/values-local.yaml \
  --wait \
  --timeout 5m
```

Verify:

```bash
kubectl get pods,deploy,svc,hpa,pdb -n auspost-local
kubectl rollout status deployment/auspost-health -n auspost-local
kubectl logs -n auspost-local deployment/auspost-health
```


## 4. Test the application and Actuator endpoints

```bash
kubectl exec -it -n auspost-local deployment/auspost-health -- /bin/sh
```


Inside the debug container:

```bash
curl http://localhost:8080/health
curl http://localhost:8080/actuator/health
curl http://localhost:8080/actuator/health/readiness
curl http://localhost:8080/actuator/health/liveness
exit
```


```json
{
  "status": "success",
  "message": "application is healthy",
  "version": "1.0.0",
  "environment": "auspost-local"
}
```

