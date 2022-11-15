Dans cet exercice vous allez créer un cluster basé sur [k0s](https://k0sproject.io), celui-ci ne sera constitué que d'une seule VM. Vous activerez la génération des logs d'audit sur ce cluster.

## Création d'une VM

Sur votre machine locale, utilisez [Multipass](https://multipass.run) pour créer une nouvelle machine virtuelle:

```
multipass launch -n k0s
```

Lancez ensuite un shell dans celle-ci:

```
multipass shell k0s
```

## Policy de logging

Le niveau de logging des logs d'audit peut être défini à différents niveau:

- None: les évènements associés ne sont pas loggués
- Metadata: les meta-données des évènements sont loggées (requestor, timestamp, resource, verb, etc.) mais les body des requêtes et réponses ne le sont pas
- Request: les meta-données et le body de la requète sont loggés, le body de la réponse n'est par contre pas loggué
- RequestResponse: les méta-données et les body des requêtes et réponses sont loggués

Dans le cadre de cet exercice nous allons considérer une Policy d'audit qui loggue les meta-données de chaque requète envoyée à l'API Server. Nous utiliserons pour cela le fichier de configuration suivant:

```
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: Metadata
```

Copiez le contenu de ce fichier dans /tmp/policy.yaml dans la VM que vous venez de créer.

## Installation du cluster basé sur k0s

Toujours dans la VM k0s, installez le binaire k0s à l'aide de la commande suivante:

```
ubuntu@k0s:~$ curl -sSLf get.k0s.sh | sudo sh
```

Générez un fichier de configuration par défaut

```
ubuntu@k0s:~$ k0s config create > /tmp/k0s.config
```

Modifiez ensuite celui-ci en ajoutant les arguments supplémentaires permettant d'activer la génération des évènements d'audit de l'API Server:

```
spec:
  api:
    ...
    extraArgs:                                     # Configuration de l'API server
      audit-policy-file: /tmp/policy.yaml          # afin que l'audit soit activé
      audit-log-path: /tmp/audit.log               # avec une policy définie

```

Note:
- les propriétés audit-policy-file et audit-log-path sont obligatoires
- des propriétes facultatives peuvent être spécifiées afin notamment de configurer la retention des logs (audit-log-maxage, audit-log-maxbackup, audit-log-maxsize)

Générez ensuite le fichier unit de systemd du controller k0s:

```
ubuntu@k0s:~$ sudo k0s install controller --single -c /tmp/k0s.config
```

puis lancez le cluster:

```
ubuntu@k0s:~$ sudo k0s start
```

Vérifiez que *k0scontroller* tourne correctement:

```
ubuntu@k0s:~$ sudo systemctl status k0scontroller
```

Après quelques dizaines de secondes vérifiez que le cluster est running:

```
ubuntu@k0s:~$ sudo k0s kubectl get nodes
```

Vous obtiendrez un résultat similaire à celui ci-dessous (le version pourrait être différente):

```
NAME   STATUS   ROLES           AGE   VERSION
k0s    Ready    control-plane   45s   v1.23.3+k0s
```

## Log d'audit

Confirmez que des logs d'audit sont bien générés dans le fichier */tmp/audit.log*. 

```
ubuntu@k0s:~$ sudo tail /tmp/audit.log
```

Créez ensuite un pod simple, par exemple:

```
ubuntu@k0s:~$ sudo k0s kubectl run nginx --image=nginx:1.20
```

Récupérez des logs d'audit liés à cette création:

```
ubuntu@k0s:~$ sudo cat /tmp/audit.log | grep nginx
```

## Cleanup

Supprimez la VM avec la commande suivante:

```
multipass delete -p k0s
```