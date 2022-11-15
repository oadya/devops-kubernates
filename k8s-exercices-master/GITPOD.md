## Objectifs

Utiliser un environnment GitPod pour effectuer des exercices permettant de comprendre les principes fondamentaux de Kubernetes

## Lancement du workspace GitPod

Cliquez sur le bouton suivant [![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#https://gitlab.com/lucj/k8s-exercices.git)

Cela va ouvrir un nouvel onglet dans votre navigateur. A l'intérieur de celui-ci vous aurez un environnement complet qui vous permettra d'effectuer les exercices définis plus bas.

## Utilisation

Il est recommandé de suivre les [instructions](#exercices) dans l'onglet courant et de réaliser les exercices dans le nouvel onglet contenant le workspace GitPod.

## Kubeconfig file

Les exercices listés ci-dessous nécessitent d'avoir accès à un cluster Kubernetes.

Avant de commencer les exercices, il est nécessaire d'effectuer les étapes suivantes dans l'environnement GitPod afin de copier le contenu de votre kubeconfig dans le fichier */home/gitpod/.kube/config*:

- copiez le contenu de votre kubeconfig
- lancez la commande suivante dans le terminal:
```
cat > $HOME/.kube/config
```
- collez le contenu de votre kubeconfig
- cliquez sur ENTER
- faire un CTRL-D

Vérifiez ensuite que vous avez bien accès à votre cluster en listant les nodes avec la commande suivante:

```
kubectl get nodes
```

## Exercices

- Pod
  * [Mon premier Pod](./Pod/pod_whoami.md)
  * [Pod avec plusieurs containers](./Pod/pod_wordpress.md)
  * [Exemple de scheduling](./Pod/pod_sheduling.md)
- Service
  * [Service de type ClusterIP](./Services/service_ClusterIP.md)
  * [Service de type NodePort](./Services/service_NodePort.md)
- Deployment
  * [Un deployment simple](./Deployment/deployment_ghost.md)
  * [Mise à jour d'un Deployment](./Deployment/rollout_rollback.md)
- DaemonSet
  * [Agent FluentBit](./DaemonSet/fluent-bit.md)
- ConfigMap
  * [Un exemple simple](./ConfigMap/configmap_nginx.md)
  * [Mise à jour d'une ConfigMap](./ConfigMap/update-config-map-in-deployment.md)
- Secret
  * [Création et utilisation d'un Secret](./Secret/secret_mongo.md)

## Status

Work in progress...
