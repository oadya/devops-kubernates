Kind (Kubernetes in Docker) permet de déployer un cluster Kubernetes de façon à ce que chacun des nodes du cluster tourne dans un container Docker.

Pour l'utiliser il suffit simplement d'installer *Docker* ainsi que la dernière release de Kind ([https://github.com/kubernetes-sigs/kind/releases](https://github.com/kubernetes-sigs/kind/releases)).

## Les Commandes

Une fois installé, la liste des commandes disponibles peut être obtenue avec la commande suivante:

```
$ kind
```

Vous obtiendrez un résultat similaire à celui ci-dessous:

```
kind creates and manages local Kubernetes clusters using Docker container 'nodes'

Usage:
  kind [command]

Available Commands:
  build       Build one of [node-image]
  completion  Output shell completion code for the specified shell (bash, zsh or fish)
  create      Creates one of [cluster]
  delete      Deletes one of [cluster]
  export      Exports one of [kubeconfig, logs]
  get         Gets one of [clusters, nodes, kubeconfig]
  help        Help about any command
  load        Loads images into nodes
  version     Prints the kind CLI version

Flags:
  -h, --help              help for kind
      --loglevel string   DEPRECATED: see -v instead
  -q, --quiet             silence all stderr output
  -v, --verbosity int32   info log verbosity
      --version           version for kind

Use "kind [command] --help" for more information about a command.
```

## Création d'un cluster composé d'un seul node

Il suffit de lancer la commande suivante pour créer un cluster (seulement un node ici) en quelques dizaines de secondes:

```
$ kind create cluster --name k8s
Creating cluster "k8s" ...
 ✓ Ensuring node image (kindest/node:v1.20.2) 🖼
 ✓ Preparing nodes 📦
 ✓ Writing configuration 📜
 ✓ Starting control-plane 🕹️
 ✓ Installing CNI 🔌
 ✓ Installing StorageClass 💾
Set kubectl context to "kind-k8s"
You can now use your cluster with:

kubectl cluster-info --context kind-k8s

Have a nice day! 👋
```

Si nous listons les containers présents, nous pouvons voir qu'un container a été créé. A l'intérieur de celui-ci tournent l'ensemble des processus de Kubernetes.

```
$ docker ps
CONTAINER ID   IMAGE                           COMMAND                  CREATED         STATUS                  PORTS                                            NAMES
b9c0535c2cba   kindest/node:v1.20.2            "/usr/local/bin/entr…"   3 minutes ago   Up 3 minutes            127.0.0.1:62796->6443/tcp                        k8s-control-plane
```

Kind a automatiquement créé un context et l'a définit en tant que context courant.

```
$ kubectl config get-contexts
CURRENT   NAME         CLUSTER      AUTHINFO      NAMESPACE
*         kind-k8s     kind-k8s     kind-k8s
...
```

Nous pouvons alors lister les nodes du cluster (un seul ici)

```
$ kubectl get nodes
NAME                STATUS   ROLES                  AGE    VERSION
k8s-control-plane   Ready    control-plane,master   5m3s   v1.20.2
```

## HA Cluster

Kind permet également de mettre en place un cluster comportant plusieurs nodes, pour cela il faut utiliser un fichier de configuration. Par exemple, le fichier suivant (*config.yaml*) définit un cluster de 3 nodes: 1 master et 2 workers.

```
# config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
```

Pour mettre en place ce nouveau cluster, il suffit de préciser le fichier de configuration dans les paramètres de lancement de la commande de création.

```
$ kind create cluster --name k8s-2 --config config.yaml
Creating cluster "k8s-2" ...
 ✓ Ensuring node image (kindest/node:v1.20.2) 🖼
 ✓ Preparing nodes 📦 📦 📦
 ✓ Writing configuration 📜
 ✓ Starting control-plane 🕹️
 ✓ Installing CNI 🔌
 ✓ Installing StorageClass 💾
 ✓ Joining worker nodes 🚜
Set kubectl context to "kind-k8s-2"
You can now use your cluster with:

kubectl cluster-info --context kind-k8s-2

Not sure what to do next? 😅  Check out https://kind.sigs.k8s.io/docs/user/quick-start/
```

Si nous listons une nouvelles fois les containers, nous en trouvons 6 nouveaux: chacun fait touner un des nodes du cluster.

```
$ docker ps
CONTAINER ID   IMAGE                       COMMAND                  CREATED          STATUS                  PORTS                                          NAMES
e7b39a790682   kindest/node:v1.20.2        "/usr/local/bin/entr…"   2 minutes ago    Up 2 minutes                                                           k8s-2-worker2
4c76ee9e5a44   kindest/node:v1.20.2        "/usr/local/bin/entr…"   2 minutes ago    Up 2 minutes                                                           k8s-2-worker
cfc735135728   kindest/node:v1.20.2        "/usr/local/bin/entr…"   2 minutes ago    Up 2 minutes            127.0.0.1:63185->6443/tcp                      k8s-2-control-plane
b9c0535c2cba   kindest/node:v1.20.2        "/usr/local/bin/entr…"   10 minutes ago   Up 10 minutes           127.0.0.1:62796->6443/tcp                      k8s-control-plane
```

Kind a automatiquement créé un context et l'a définit en tant que context courant.

```
$ kubectl config get-contexts
CURRENT   NAME         CLUSTER      AUTHINFO     NAMESPACE
          kind-k8s     kind-k8s     kind-k8s
*         kind-k8s-2   kind-k8s-2   kind-k8s-2
...
```

Nous pouvons dont directement lister les nodes du cluster:

```
$ kubectl get nodes
NAME                  STATUS   ROLES                  AGE     VERSION
k8s-2-control-plane   Ready    control-plane,master   2m22s   v1.20.2
k8s-2-worker          Ready    <none>                 107s    v1.20.2
k8s-2-worker2         Ready    <none>                 107s    v1.20.2
```

La commande suivante permet de lister les clusters présents:

```
$ kind get clusters
k8s
k8s-2
```

## Cleanup

Afin de supprimer un cluster créé avec *Kind*, il suffit de lancer la commande `kind delete cluster --name CLUSTER_NAME`.

Les commandes suivantes suppriment les 2 clusters créés précédemment:

```
$ kind delete cluster --name k8s
Deleting cluster "k8s" ...

$ kind delete cluster --name k8s-2
Deleting cluster "k8s-2" ...
```
