TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
curl -k -H "Authorization: Bearer $TOKEN" https://[CONTROL-PLANE-NODE-NAME]:10259/metrics
