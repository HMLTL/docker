# rd-fluxcd-lesson — GitOps з Flux CD (Helm-варіант)

Повний GitOps-цикл для застосунку `course-app` з мульти-середовищним
деплоєм (development / production) через Flux CD. Замість Kustomize
base/overlays використовується **Helm-чарт + Flux `HelmRelease`** на кожне
середовище.


## Структура

```
flux/
├── charts/
│   └── course-app/                    # Етапи 2-4: один параметризований чарт
│       ├── Chart.yaml
│       ├── values.yaml                # дефолти (≈ development)
│       └── templates/
│           ├── _helpers.tpl
│           ├── deployment.yaml        # replicas зникає, коли hpa.enabled=true
│           ├── service.yaml           # ClusterIP
│           ├── ingress.yaml
│           ├── dragonfly.yaml         # kind: Dragonfly (Operator Pattern), if .enabled
│           ├── hpa.yaml               # HPA, if .enabled
│           └── pdb.yaml               # PodDisruptionBudget, if .enabled
└── clusters/my-cluster/               # Етап 5: що Flux реально слухає
    ├── apps-development.yaml          # HelmRelease app-dev  -> namespace development
    ├── apps-production.yaml           # HelmRelease app-prod -> namespace production
    └── dragonfly-operator.yaml        # (Опц.) HelmRepository + HelmRelease оператора
```

> Жодного `kustomization.yaml`. `flux-system` (створений під час bootstrap)
> слухає `./clusters/my-cluster` і **сам генерує kustomization** на льоту,
> скануючи всі `.yaml` у папці. Тому маніфести оператора достатньо просто
> покласти сюди — окрема Flux `Kustomization`-обгортка не потрібна.

> Один чарт, два `HelmRelease`. Різниця між середовищами — лише у блоці
> `spec.values` кожного релізу (репліки, ingress host, resources, HPA,
> кількість реплік Dragonfly). Це і є GitOps-аналог overlays.

### Як середовища відрізняються

| Параметр              | development        | production            |
|-----------------------|--------------------|-----------------------|
| Namespace             | `development`      | `production`          |
| Реплік застосунку     | 1                  | 3 (далі керує HPA)    |
| HPA                   | вимкнено           | 3 → 10 (CPU 70/Mem 80)|
| Requests/Limits       | дефолтні (малі)    | задані явно           |
| Реплік Dragonfly      | 1                  | 2                     |
| Ingress host          | course-app.dev.local | course-app.local    |
| Hardening (SecCtx/PDB)| вимкнено           | увімкнено             |

## Запуск (на машині з кластером)

### Етап 1 — bootstrap

```bash
# 1. Створити публічний репозиторій rd-fluxcd-lesson на GitHub (пустий / з README).
# 2. Створити Personal Access Token (repo scope) і експортувати:
export GITHUB_TOKEN=<ваш_токен>

# 3. Прив'язати Flux до репозиторію:
flux bootstrap github \
  --owner=<ВАШ_GITHUB_USERNAME> \
  --repository=rd-fluxcd-lesson \
  --branch=main \
  --path=./clusters/my-cluster \
  --personal
```

Після bootstrap у репозиторії з'явиться `clusters/my-cluster` із системними
маніфестами Flux і GitRepository з ім'ям `flux-system` — саме на нього
посилаються `chart.spec.sourceRef` у наших `HelmRelease`.

### Етапи 2–5 — закомітити застосунок

Скопіювати вміст цієї папки в корінь репозиторію `rd-fluxcd-lesson` і
запушити в `main`. Flux підхопить `HelmRelease` з `clusters/my-cluster`,
підтягне чарт з `./charts/course-app` тієї ж гілки і встановить обидва релізи.

## Локальна перевірка шаблонів (без кластера)

```bash
helm lint charts/course-app
helm template course-app charts/course-app                       # дефолти (dev)
helm template course-app charts/course-app --set hpa.enabled=true --set replicaCount=3
```

## Перевірка (Definition of Done)

```bash
flux get helmreleases -A          # app-dev, app-prod, dragonfly-operator -> Ready
flux get kustomizations           # flux-system -> Ready
kubectl get ns development production
kubectl get pods,dragonfly -n development      # 1 под app + Dragonfly (1 інстанс)
kubectl get pods,dragonfly,hpa -n production   # 3 поди app + Dragonfly(2) + HPA
```

Drift Check:

```bash
kubectl delete svc course-app -n production
# протягом ~хвилини Flux відновить сервіс (HelmRelease interval: 1m)
```

## Залежність від оператора (опціональний етап)

Ресурси `kind: Dragonfly` обслуговує Dragonfly Operator. За замовчуванням
оператор встановлюється через Flux (`dragonfly-operator.yaml`), а обидва
app-`HelmRelease` мають `dependsOn` на нього — тож релізи чекають готовності
CRD `Dragonfly`.


