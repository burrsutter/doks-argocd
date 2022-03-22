https://docs.digitalocean.com/reference/doctl/how-to/install/

https://docs.digitalocean.com/products/kubernetes/how-to/connect-to-cluster/

https://www.digitalocean.com/community/tutorials/how-to-deploy-to-kubernetes-using-argo-cd-and-gitops

brew install doctl

cd ~/devnation/doks

doctl auth init

https://cloud.digitalocean.com/account/api/tokens

doctl kubernetes cluster list

Download argocd binary
https://github.com/argoproj/argo-cd/releases

mkdir .kube

export KUBECONFIG=~/devnation/doks/.kube/config-ams3
export KUBECONFIG=~/devnation/doks/.kube/config-blr1
export KUBECONFIG=~/devnation/doks/.kube/config-tor1

export KUBE_EDITOR="code -w"
export PATH=~/devnation/bin:$PATH

doctl kubernetes cluster create ams3-kubernetes --region ams3 --node-pool="name=worker-pool;count=3"
doctl kubernetes cluster create blr1-kubernetes --region blr1 --node-pool="name=worker-pool;count=3"
doctl kubernetes cluster create tor1-kubernetes --region tor1 --node-pool="name=worker-pool;count=3"

doctl kubernetes cluster list

doctl k8s cluster kubeconfig show ams3-kubernetes >> $KUBECONFIG
# doctl kubernetes cluster kubeconfig save ams3-kubernetes
doctl k8s cluster kubeconfig show blr1-kubernetes >> $KUBECONFIG
# doctl kubernetes cluster kubeconfig save blr1-kubernetes
doctl k8s cluster kubeconfig show tor1-kubernetes >> $KUBECONFIG
# doctl kubernetes cluster kubeconfig save tor1-kubernetes

kubectl cluster-info

kubectl get nodes

# Test App

kubectl apply -f mystuff/namespace.yaml

kubectl config set-context --current --namespace=mystuff

kubectl apply -f mystuff/deployment.yaml

kubectl apply -f mystuff/service.yaml

kubectl get service quarkus-demo -o json

IP=$(kubectl get service quarkus-demo -o jsonpath="{.status.loadBalancer.ingress[0].ip}"):8080

echo $IP

curl $IP

while true
do curl $IP
sleep .3
done

kubectl delete namespace mystuff


# ArgoCD Hub

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

ARGOCD_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
# really should change the default password

ARGOCD_IP=$(kubectl get service argocd-server -o jsonpath="{.status.loadBalancer.ingress[0].ip}"):80

echo $ARGOCD_IP

open http://$ARGOCD_IP

# Login with "admin" and $ARGOCD_PASS

argocd login --insecure --grpc-web $ARGOCD_IP  --username admin --password $ARGOCD_PASS

# you can change the password via "argocd account update-password"
# but it does not update the secret and can not be recovered

# Spoke 1
kubectl config get-contexts -o name
argocd cluster add --kubeconfig $KUBECONFIG do-blr1-blr1-kubernetes

# Spoke 2
kubectl config get-contexts -o name
argocd cluster add --kubeconfig $KUBECONFIG do-tor1-tor1-kubernetes

argocd cluster list

https://www.screencast.com/t/UXPfHbnOKHG

# Deploy an app
argocd app create helm-guestbook --repo https://github.com/argoproj/argocd-example-apps.git --path helm-guestbook --dest-server https://kubernetes.default.svc --dest-namespace default
argocd app sync helm-guestbook
argocd app delete helm-guestbook



doctl k8s cluster delete ams3-kubernetes
doctl k8s cluster delete blr1-kubernetes
doctl k8s cluster delete tor1-kubernetes