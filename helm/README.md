# Helm — course-app + Bitnami Redis

## Швидкий старт

```bash
# 1. Додати Bitnami репозиторій
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# 2. Завантажити залежності (bitnami/redis)
cd helm/course-app
helm dependency build

# 3. Встановити чарт (у minikube)
helm install course-app . --namespace default

# 4. Перевірити
kubectl get pods
kubectl get svc
kubectl get ingress
```

## Кастомізація

```bash
# Змінити кількість реплік та хост Ingress
helm install course-app . \
  --set replicaCount=5 \
  --set ingress.host=myapp.example.com

# Вимкнути Ingress
helm install course-app . --set ingress.enabled=false

# Увімкнути Redis auth (prod)
helm install course-app . --set redis.auth.enabled=true --set redis.auth.password=secret123
```

## Оновлення

```bash
helm upgrade course-app .
```

## Видалення

```bash
helm uninstall course-app
```

