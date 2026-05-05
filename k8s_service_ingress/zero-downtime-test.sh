#!/usr/bin/env zsh
# zero-downtime-test.sh
# Демонструє, що під з failed readiness check зникає з Endpoints,
# а трафік продовжує йти на здорові репліки.

set -euo pipefail

NAMESPACE=${NAMESPACE:-default}
DEPLOYMENT=course-app
SERVICE=course-app-service

echo "══════════════════════════════════════════════════════"
echo " Zero-Downtime Test: readiness probe failure"
echo "══════════════════════════════════════════════════════"

# 1. Поточний стан подів
echo "\n[1] Поточні поди:"
kubectl get pods -l app=${DEPLOYMENT} -n ${NAMESPACE} -o wide

# 2. Поточні Endpoints
echo "\n[2] Endpoints до тесту:"
kubectl get endpoints ${SERVICE} -n ${NAMESPACE}

# 3. Вибрати один под (перший)
TARGET_POD=$(kubectl get pods -l app=${DEPLOYMENT} -n ${NAMESPACE} \
  -o jsonpath='{.items[0].metadata.name}')
echo "\n[3] Цільовий под: ${TARGET_POD}"

# 4. Зламати readiness probe — додати файл-блокування
#    (якщо застосунок перевіряє /health → тут симулюємо через exec у нового пода)
#    Альтернатива: тимчасово змінити readinessProbe на неіснуючий шлях
echo "\n[4] Симулюємо збій: exec у pod, зупиняємо процес Node.js (SIGSTOP)"
kubectl exec -n ${NAMESPACE} ${TARGET_POD} -- kill -STOP 1

echo "\n[5] Чекаємо 15с поки k8s зафіксує збій readiness probe..."
sleep 15

# 5. Перевірити що IPзник з Endpoints
echo "\n[6] Endpoints після збою (IP пода має зникнути):"
kubectl get endpoints ${SERVICE} -n ${NAMESPACE}

echo "\n[7] Стан подів (TARGET_POD має бути 0/1 Ready):"
kubectl get pods -l app=${DEPLOYMENT} -n ${NAMESPACE}

# 6. Надіслати кілька запитів — усі мають пройти через інші поди
echo "\n[8] Перевірка трафіку (10 запитів через Ingress або port-forward):"
echo "    Якщо Ingress активний: curl -s http://course-app.local/health"
echo "    Якщо port-forward:     kubectl port-forward svc/${SERVICE} 8080:8080 &"
echo "                           for i in \$(seq 1 10); do curl -s localhost:8080/health; done"

# 7. Відновити под
echo "\n[9] Відновлюємо под (SIGCONT):"
kubectl exec -n ${NAMESPACE} ${TARGET_POD} -- kill -CONT 1

echo "\n[10] Чекаємо відновлення readiness..."
sleep 15

echo "\n[11] Endpoints після відновлення (IP має з'явитись знову):"
kubectl get endpoints ${SERVICE} -n ${NAMESPACE}

echo "\n[12] Фінальний стан подів:"
kubectl get pods -l app=${DEPLOYMENT} -n ${NAMESPACE}

echo "\n✅ Тест завершено"

