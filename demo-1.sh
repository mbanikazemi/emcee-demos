#!/bin/bash
source init.sh

## ---

echo "DEMO: Homogeneous #1: sleep.foo (cluster1) -> httpbin.foo (cluster2)"

echo "---"

echo "Deploy sleep.foo on CTX_CLUSTER1"
kubectl config use-context $CTX_CLUSTER1
kubectl create namespace foo
kubectl label namespace foo istio-injection=enabled
kubectl apply -n foo -f https://raw.githubusercontent.com/istio/istio/release-1.5/samples/sleep/sleep.yaml

echo "---"

echo "Deploy httpbin.foo on CTX_CLUSTER2"
kubectl config use-context $CTX_CLUSTER2
kubectl create namespace foo
kubectl label namespace foo istio-injection=enabled
kubectl apply -n foo -f https://raw.githubusercontent.com/istio/istio/release-1.5/samples/httpbin/httpbin.yaml

echo "---"

echo "Expose httpbin.foo on $CTX_CLUSTER2 by modifying the Service with an annotation"
kubectl apply -n foo -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  labels:
    app: httpbin
  annotations:
    emcee.io/expose: "true"
spec:
  ports:
  - name: http
    port: 8000
    targetPort: 80
  selector:
    app: httpbin
EOF

sleep 20s

echo "Test sleep.foo -> httpbin.foo"
kubectl config use-context $CTX_CLUSTER1
echo "curl httpbin:8000"
kubectl exec -n foo $(kubectl get pod -n foo -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep  -- curl -I http://httpbin:8000/
echo "curl httpbin.foo:8000"
kubectl exec -n foo $(kubectl get pod -n foo -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep  -- curl -I http://httpbin.foo:8000/

echo "Delete httpbin.foo"
kubectl config use-context $CTX_CLUSTER2
kubectl delete deploy httpbin -n foo
kubectl delete svc httpbin -n foo

## ---

echo "DEMO: Homogeneous #2: sleep.foo (cluster1) -> httpbin.bar (cluster2)"

echo "Deploy httpbin.bar on CTX_CLUSTER2"
kubectl config use-context $CTX_CLUSTER2
kubectl create namespace bar
kubectl label namespace bar istio-injection=enabled
kubectl apply -n bar -f https://raw.githubusercontent.com/istio/istio/release-1.5/samples/httpbin/httpbin.yaml


echo "Expose httpbin.bar on $CTX_CLUSTER2 by modifying the Service with an annotation"
kubectl apply -n bar -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  labels:
    app: httpbin
  annotations:
    emcee.io/expose: "true"
spec:
  ports:
  - name: http
    port: 8000
    targetPort: 80
  selector:
    app: httpbin
EOF

sleep 20s

echo "Create bar namespace and httpbin Service on CTX_CLUSTER1 for DNS resolution"
kubectl config use-context $CTX_CLUSTER1
kubectl create namespace bar
kubectl apply -n bar -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  labels:
    app: httpbin
spec:
  ports:
  - name: http
    port: 8000
    targetPort: 80
  selector:
    app: httpbin
EOF

echo "Test sleep.foo -> httpbin.bar"
kubectl config use-context $CTX_CLUSTER1
echo "curl httpbin.bar:8000"
kubectl exec -n foo $(kubectl get pod -n foo -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep  -- curl -I http://httpbin.bar:8000/

source cleanup.sh