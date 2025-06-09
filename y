apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: t4
  namespace: argocd
spec:
  project: default
  destination:
    server: https://kubernetes.default.svc
    namespace: t4

  # ↓ switch to *sources* (plural) so you can mix chart + values
  sources:
    # 1️⃣  The Helm chart (remains in your OCI registry)
    - repoURL: oci://pamepkshbr02.harel-office.com/as400-charts
      chart: t4
      targetRevision: "1.0.4"
      helm:
        releaseName: t4
        # pick any number of files from the Git repo below
        valueFiles:
          - $values/t4/values-prod.yaml

    # 2️⃣  The Git repo that only hosts the overrides
    - repoURL: https://github.com/my-org/t4-config.git   # <-- your repo
      targetRevision: main                              # branch / tag
      ref: values                                       # binds $values
      # omit “path” to use this repo purely as a values bucket

  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true