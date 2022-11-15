Dans cet exercice, vous allez tout d'abord créer un cluster avec l'outil *kubeadm* dans une version antérieure à la version actuellement disponible. Vous mettrez ensuite ce cluster à jour vers une version plus récente.

Le cluster sera constitué d'un node master et d'un node worker mais le processus de mise à jour d'un cluster constitué de plusieurs masters et plusieurs workers est similaire.

## Mise en place d'un cluster dans une version antérieur

### Création des VMs

Afin de créer les VMs qui seront utilisées dans le cluster, vous allez utiliser [Multipass](https://multipass.run), un outil qui permet de créer des machines virtuelles très simplement.

Installez Multipass (celui-ci est disponible pour Windows, Linux et MacOS) puis lancez les commandes suivantes pour créer 2 machines virtuelles nommées *master* et *worker*

```
multipass launch -n master
multipass launch -n worker
```

### Initialisation du cluster

Une fois les VMs *master* et *worker* créées, vous allez initialiser le cluster.

Lancez tout d'abord un shell sur le node *master*:

```
multipass shell master
```

Depuis ce shell lancez la commande suivante, celle-ci installe les dépendances nécessaires sur le master (container runtime et quelques packages) et initialise le cluster avec une version précédente de Kubernetes:

```
ubuntu@master:~$ curl -sSL https://luc.run/kubeadm/previous/master.sh | bash
```

Lancez ensuite la commande qui initialize le cluster:

```
ubuntu@master:~$ sudo kubeadm init --ignore-preflight-errors=NumCPU,Mem
```

Note: le flag *--ignore-preflight-errors* permet de forcer l'installation même si les requirements en terme de CPU et Memoire ne sont pas respectés (cette option ne sera évidememnt pas utilisée pour la mise en place d'un cluster de production)

Après quelques dizaines de secondes, vous obtiendrez alors une commande qui vous servira, par la suite, à ajouter un node worker au cluster qui vient d'être créé.

Exemple de commande retournée (les tokens que vous obtiendrez seront différents):

```
sudo kubeadm join 192.168.64.40:6443 --token xrtqvq.9zmmzjx16b4jc4q8 --discovery-token-ca-cert-hash sha256:fabe1bbc0264b36a624b0c7284fe58151dad0640c81bff9a9f0e33fecd377e1a
```

Toujours depuis le node master, récupérer le fichier kubeconfig pour l'utilisateur courant (*ubuntu*):

```
ubuntu@master:~$ mkdir -p $HOME/.kube
ubuntu@master:~$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
ubuntu@master:~$ sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### Ajout d'un node worker

Une fois le cluster initialisé, vous allez ajouter un node worker.

Lancez tout d'abord un shell sur *worker*:

```
multipass shell worker
```

Depuis ce shell lancez la commande suivante, celle-ci installe les dépendances nécessaires sur le worker (dans la même version que celle utilisée sur le master)

```
ubuntu@worker:~$ curl -sSL https://luc.run/kubeadm/previous/worker.sh | bash
```

Lancez ensuite la commande retournée lors de l'étape d'initialisation (*sudo kubeadm join ...*) afin d'ajouter le node *worker* au cluster.

Note: si vous avez perdu la commande d'ajout de node, vous pouvez la générer avec la commande suivante (à lancer depuis le node master)

```
ubuntu@master:~$ sudo kubeadm token create --print-join-command
```

Après quelques dizaines de secondes, vous obtiendrez rapidement une confirmation indiquant que la VM *worker* fait maintenant partie du cluster::

```
This node has joined the cluster
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.
...
```

### Etat du cluster

Listez à présent les nodes du cluster avec la commande suivante:

```
ubuntu@master:~$ kubectl get nodes
```

Vous obtiendrez un résultat similaire à celui ci-dessous (votre version pourra cependant être différente)

```
NAME     STATUS     ROLES                  AGE     VERSION
master   NotReady   control-plane,master   6m12s   v1.22.6
worker   NotReady   <none>                 2m28s   v1.22.6
```

Les nodes sont dans l'état *NotReady*, cela vient du fait qu'aucun plugin network n'a été installé pour le moment.

### Installation d'un plugin network

Afin que le cluster soit opérationnel il est nécessaire d'installer un plugin network. Plusieurs plugins sont disponibles (WeaveNet, Calico, Flannel, Cilium, …), chacun implémente la spécification CNI (Container Network Interface) et permet notamment la communication entre les différents Pods du cluster.

Vous allez ici installer le plugin WeaveNet en utilisant pour cela La commande suivante:

```
ubuntu@master:~$ kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
```

Plusieurs ressources sont alors créées pour mettre en place cette solution de networking:

```
serviceaccount/weave-net created
clusterrole.rbac.authorization.k8s.io/weave-net created
clusterrolebinding.rbac.authorization.k8s.io/weave-net created
role.rbac.authorization.k8s.io/weave-net created
rolebinding.rbac.authorization.k8s.io/weave-net created
daemonset.apps/weave-net created
```


Après quelques secondes, les nodes apparaitront dans l'état *Ready*, vous pourrez le constater avec la commande suivante:

```
$ kubectl get nodes
```

Le cluster est prêt à être utilisé.

## Mise à jour du cluster

Le cluster précédent à été créé avec une ancienne version de Kubernetes, vous allez à présent le mettre à jour vers une version plus récente.

### Mise à jour du node master

La mise à jour commence par les nodes master (un seul dans le cadre de cet exercice)

#### Mise à jour de kubeadm

Depuis un shell root sur le node master, lancez la commande suivante afin de lister les versions de *kubeadm* actuellement disponibles:

```
ubuntu@master:~$ sudo apt update && sudo apt-cache policy kubeadm
```

Vous obtiendrez un résultat proche de celui ci-dessous:

```
kubeadm:
  Installed: 1.22.6-00
  Candidate: 1.23.4-00
  Version table:
     1.23.4-00 500
        500 http://apt.kubernetes.io kubernetes-xenial/main arm64 Packages
     1.23.3-00 500
        500 http://apt.kubernetes.io kubernetes-xenial/main arm64 Packages
     1.23.2-00 500
        500 http://apt.kubernetes.io kubernetes-xenial/main arm64 Packages
     1.23.1-00 500
        500 http://apt.kubernetes.io kubernetes-xenial/main arm64 Packages
     1.23.0-00 500
        500 http://apt.kubernetes.io kubernetes-xenial/main arm64 Packages
     1.22.7-00 500
        500 http://apt.kubernetes.io kubernetes-xenial/main arm64 Packages
 *** 1.22.6-00 500
        500 http://apt.kubernetes.io kubernetes-xenial/main arm64 Packages
        100 /var/lib/dpkg/status
     1.22.5-00 500
        500 http://apt.kubernetes.io kubernetes-xenial/main arm64 Packages
...
```

Il est possible que vous obteniez un résultat différent, les mises à jour de Kubernetes étant relativement fréquentes (3 releases mineures par an depuis la version 1.22.0). Nous effectuerons ici une mise à jour de la version 1.22.6 vers la version 1.23.4.


Utilisez la commande suivante afin de mettre à jour *kubeadm* sur le node master:

```
ubuntu@master:~$ sudo apt-mark unhold kubeadm && \
                 sudo apt-get update && \
                 sudo apt-get install -y kubeadm=1.23.4-00 && \
                 sudo apt-mark hold kubeadm
```

#### Passage du node en mode Drain

En utilisant la commande suivante, passez le node master en *drain* de façon à ce que les Pods applicatifs (si il y en a) soient re-schedulés sur les autres nodes du cluster.

```
ubuntu@master:~$ kubectl drain master --ignore-daemonsets
```

Vous obtiendrez le résultat suivant:

```
node/master cordoned
WARNING: ignoring DaemonSet-managed Pods: kube-system/kube-proxy-xwx2c, kube-system/weave-net-9cqj4
node/master drained
```

Lancez ensuite la simulation de la mise à jour avec la commande suivante:

```
ubuntu@master:~$ sudo kubeadm upgrade plan
```

Vous obtiendrez un résultat similaire à celui ci-dessous:

```
[upgrade/config] Making sure the configuration is correct:
[upgrade/config] Reading configuration from the cluster...
[upgrade/config] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
[preflight] Running pre-flight checks.
[upgrade] Running cluster health checks
[upgrade] Fetching available versions to upgrade to
[upgrade/versions] Cluster version: v1.22.7
[upgrade/versions] kubeadm version: v1.23.4
[upgrade/versions] Target version: v1.23.4
[upgrade/versions] Latest version in the v1.22 series: v1.22.7

Components that must be upgraded manually after you have upgraded the control plane with 'kubeadm upgrade apply':
COMPONENT   CURRENT       TARGET
kubelet     2 x v1.22.6   v1.23.4

Upgrade to the latest stable version:

COMPONENT                 CURRENT   TARGET
kube-apiserver            v1.22.7   v1.23.4
kube-controller-manager   v1.22.7   v1.23.4
kube-scheduler            v1.22.7   v1.23.4
kube-proxy                v1.22.7   v1.23.4
CoreDNS                   v1.8.4    v1.8.6
etcd                      3.5.0-0   3.5.1-0

You can now apply the upgrade by executing the following command:

	kubeadm upgrade apply v1.23.4

_____________________________________________________________________


The table below shows the current state of component configs as understood by this version of kubeadm.
Configs that have a "yes" mark in the "MANUAL UPGRADE REQUIRED" column require manual config upgrade or
resetting to kubeadm defaults before a successful upgrade can be performed. The version to manually
upgrade to is denoted in the "PREFERRED VERSION" column.

API GROUP                 CURRENT VERSION   PREFERRED VERSION   MANUAL UPGRADE REQUIRED
kubeproxy.config.k8s.io   v1alpha1          v1alpha1            no
kubelet.config.k8s.io     v1beta1           v1beta1             no
_____________________________________________________________________
```

Vous pouvez alors lancer la mise à jour avec la commande indiquée:

```
ubuntu@master:~$ sudo kubeadm upgrade apply v1.23.4
```

Celle-ci prendra quelques minutes, vous devriez ensuite obtenir le message suivant:

```
...
[upgrade/successful] SUCCESS! Your cluster was upgraded to "v1.23.4". Enjoy!

[upgrade/kubelet] Now that your control plane is upgraded, please proceed with upgrading your kubelets if you haven't already done so.
```

#### Passage du node master en mode Uncordon

Modifiez le node master de façon à le rendre de nouveau "schedulable".

```
ubuntu@master:~$ kubectl uncordon master
node/master uncordoned
```

Note: dans le cas d'un cluster avec plusieurs master, il faudrait également mettre à jour kubeadm sur les autres masters puis lancer la commande suivante sur chacun d'entres eux:

```
$ kubeadm upgrade NODE_IDENTIFIER
```

#### Mise à jour de kubelet et kubectl

Depuis un shell sur le node master, utilisez la commande suivante afin de mettre à jour *kubelet* et *kubectl*:

```
ubuntu@master:~$ sudo apt-mark unhold kubelet kubectl && \
                 sudo apt-get update && \
                 sudo apt-get install -y kubelet=1.23.4-00 kubectl=1.23.4-00 && \
                 sudo apt-mark hold kubelet kubectl
```

Redémarrez ensuite *kulelet*

```
ubuntu@master:~$ sudo systemctl restart kubelet
```

Si vous listez les nodes du cluster, vous verrez qu'il sont maintenant dans des versions différentes:

```
$ kubectl get nodes
NAME     STATUS   ROLES                  AGE   VERSION
master   Ready    control-plane,master   20m   v1.23.4
worker   Ready    <none>                 19m   v1.22.6
```

Dans la partie suivante, vous allez mettre à jour le node *worker*.

### Mise à jour du node worker

Dans le cas d'un cluster avec plusieurs workers, il est nécessaire d'effectuer ces actions sur chacun des workers, l'un après l'autre.

#### Mise à jour de kubeadm

Lancez un shell sur le worker:

```
multipass shell worker
```

Utilisez la commande suivante pour mettre à jour le binaire *kubeadm*:

```
ubuntu@worker:~$ sudo apt-mark unhold kubeadm && \
                 sudo apt-get update && \
                 sudo apt-get install -y kubeadm=1.23.4-00 && \
                 sudo apt-mark hold kubeadm
```

#### Passage du node en mode Drain

Lancez un shell sur le master:

```
multipass shell master
```

Préparez le node *worker* pour le maintenance en la passant en mode *drain*:

```
ubuntu@master:$ kubectl drain worker --ignore-daemonsets
```

#### Mise à jour de la configuration de kubelet

Depuis un shell sur le node *worker*, lancez la commande suivante afin de mettre à jour la configuration de *kubelet*.

```
ubuntu@worker:~$ sudo kubeadm upgrade node
```

Vous obtiendrez un résultat similaire à celui ci-dessous:

```
[upgrade] Reading configuration from the cluster...
[upgrade] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
W0301 09:40:02.576462    8138 utils.go:69] The recommended value for "resolvConf" in "KubeletConfiguration" is: /run/systemd/resolve/resolv.conf; the provided value is: /run/systemd/resolve/resolv.conf
[preflight] Running pre-flight checks
[preflight] Skipping prepull. Not a control plane node.
[upgrade] Skipping phase. Not a control plane node.
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[upgrade] The configuration for this node was successfully updated!
[upgrade] Now you should go ahead and upgrade the kubelet package using your package manager.
```

#### Mise à jour de kubelet et kubectl

Mettez ensuite à jour les binaires *kubelet* et *kubectl* à jour:

```
ubuntu@worker:~$ sudo apt-mark unhold kubelet kubectl && \
                 sudo apt-get update && \
                 sudo apt-get install -y kubelet=1.23.4-00 kubectl=1.23.4-00 && \
                 sudo apt-mark hold kubelet kubectl
```

Puis redémarrez *kubelet* à l'aide de la commande suivante:

```
ubuntu@worker:~$ sudo systemctl restart kubelet
```

Vous pouvez ensuite rendre le node "schedulable" (depuis le node *master*)

```
ubuntu@master:~$ kubectl uncordon worker
```

Les nodes *master* et *worker* sont maintenant à jour.

## Test

Le cluster est maintenant disponible dans la nouvelle version:

```
ubuntu@master:~$ kubectl get nodes
NAME     STATUS   ROLES                  AGE   VERSION
master   Ready    control-plane,master   34m   v1.23.4
worker   Ready    <none>                 33m   v1.23.4
```

Pour un cluster constitué de plusieurs masters et de plusieurs workers, il faudrait tout d'abord mettre les masters à jour puis le faire pour l'ensemble des workers.