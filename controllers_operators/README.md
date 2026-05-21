# Controllers & Operators — Dragonfly + RBAC

## Завдання 1: Dragonfly Operator

### Крок 1. Встановлення оператора

```bash
# Встановити CRD та Operator (офіційний метод)
kubectl apply -f https://raw.githubusercontent.com/dragonflydb/dragonfly-operator/main/manifests/dragonfly-operator.yaml
```

> Оператор буде встановлено в namespace `dragonfly-operator-system`.
> GitHub: https://github.com/dragonflydb/dragonfly-operator

### Крок 2. Перевірка CRD

```bash
kubectl api-resources | grep dragonfly
# dragonflies   df   dragonflydb.io/v1alpha1   true   Dragonfly
```

### Крок 3. Розгортання інстансу Dragonfly

```bash
# Подивитись доступні поля
kubectl explain dragonfly.spec

# Застосувати маніфест
kubectl apply -f controllers_operators/dragonfly.yaml

# Перевірити статус
kubectl describe dragonflies.dragonflydb.io dragonfly-sample
kubectl get dragonfly
kubectl get pods

# Підключитись через redis-cli для перевірки
kubectl run -it --rm --restart=Never redis-cli --image=redis:7.0.10 -- \
  redis-cli -h dragonfly-sample.default
```

### Крок 4. Переключити course-app на Dragonfly

```bash
kubectl apply -f controllers_operators/course-app-deployment.yaml
```

---

## Завдання 2: RBAC для Custom Resources

```bash
kubectl apply -f controllers_operators/rbac.yaml
```

---

## Завдання 3: Верифікація (auth can-i)

```bash
# 1. Перевірка доступу на читання (Має бути "yes")
kubectl auth can-i list dragonflies --as=system:serviceaccount:default:db-viewer
# yes

kubectl auth can-i get dragonflies --as=system:serviceaccount:default:db-viewer
# yes

kubectl auth can-i watch dragonflies --as=system:serviceaccount:default:db-viewer
# yes

# 2. Перевірка заборони на видалення (Має бути "no")
kubectl auth can-i delete dragonflies --as=system:serviceaccount:default:db-viewer
# no

# 3. Перевірка заборони на зміну (Має бути "no")
kubectl auth can-i update dragonflies --as=system:serviceaccount:default:db-viewer
# no

kubectl auth can-i create dragonflies --as=system:serviceaccount:default:db-viewer
# no
```

