#!/bin/sh

ping_test () {
    for ip in $(kubectl get pods -ojson | jq -r '.items[].status.podIP'); 
    do echo $ip
        kubectl exec -it tester -n test -- timeout 2 ping $ip -c2
        echo "*************************************"
        echo
    done
}

echo "In this test, there is a reference pod which will not be applied with NP and ping request to it should be always allowed no matter if allow-all or deny-all is applied."
kubectl apply -f https://raw.githubusercontent.com/haouc/dev-tests/main/netpol/nginx-service.yaml
kubectl apply -f https://raw.githubusercontent.com/haouc/dev-tests/main/netpol/test-pod.yaml
echo "Scaling nginx pods to 15"
kubectl scale deploy nginx --replicas=15
echo "Waiting for 10 seconds..."
sleep 10
echo "Checking PEs"
echo
kubectl get policyendpoint -A
echo "Should be 15 nginx pods running"
kubectl get pods | grep nginx | grep Running | wc -l
echo "Checking PEs"
echo
kubectl get policyendpoint -A
echo "Apply deny-all NP"
kubectl apply -f https://raw.githubusercontent.com/haouc/dev-tests/main/netpol/deny-all.yaml
echo "Waiting for 5 seconds..."
sleep 5
echo "Checking PEs"
echo
kubectl get policyendpoint -A
echo "[Ping tests] Deny all: all pods should deny ping requests except ONE pod which is the reference"
ping_test
echo "Apply allow-all NP"
kubectl apply -f https://raw.githubusercontent.com/haouc/dev-tests/main/netpol/allow-all.yaml
echo "Waiting for 5 seconds..."
sleep 5
echo "Checking PEs"
echo
kubectl get policyendpoint -A
echo "[Ping tests] Deny all + allow all: all pods should allow ping requests"
ping_test
echo "Scaling nginx pods to 27"
kubectl scale deploy nginx --replicas=27
echo "Waiting for 10 seconds..."
sleep 10
echo "Checking PEs"
echo
kubectl get policyendpoint -A
echo "Scaling nginx pods to 11"
kubectl scale deploy nginx --replicas=11
echo "Waiting for 10 seconds..."
sleep 10
echo "Checking PEs"
echo
kubectl get policyendpoint -A
echo "Scaling nginx pods to 22"
kubectl scale deploy nginx --replicas=22
echo "Waiting for 10 seconds..."
sleep 10
echo "Checking PEs"
echo
kubectl get policyendpoint -A
echo "Scaling nginx pods to 15"
kubectl scale deploy nginx --replicas=15
echo "Checking PEs"
echo
kubectl get policyendpoint -A
echo "[Ping tests] Deny all + allow all: all pods should allow ping requests after multiple scaling"
ping_test
echo "Removing allow-all NP"
kubectl delete -f https://raw.githubusercontent.com/haouc/dev-tests/main/netpol/allow-all.yaml
echo "Waiting for 5 seconds..."
sleep 5
echo "Checking PEs"
echo
kubectl get policyendpoint -A
echo "[Ping tests] Deny all: all pods should deny ping requests after removing allow-all NP except ONE pod which is the reference"
ping_test
echo "Removing deny-all NP"
kubectl delete -f https://raw.githubusercontent.com/haouc/dev-tests/main/netpol/deny-all.yaml
echo "Waiting for 5 seconds..."
sleep 5
echo "Checking PEs"
echo
kubectl get policyendpoint -A
echo "[Ping tests] No NPs: all pods should allow ping requests after removing all NPs"
ping_test
echo "Deleting resources"
kubectl delete -f https://raw.githubusercontent.com/haouc/dev-tests/main/netpol/test-pod.yaml -f https://raw.githubusercontent.com/haouc/dev-tests/main/netpol/nginx-service.yaml

