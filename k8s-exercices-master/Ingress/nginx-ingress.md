
Dans cet exercice vous allez installer un Ingress Controller basé sur Nginx (il existe également d'autres implémentations de Ingress Controller: *HAProxy*, *Traefik*, ...).

Un Ingress Controller est nécessaire afin de prendre en compte la ressource Ingress utilisées pour exposer les services à l'extérieur du cluster. C'est un reverse-proxy qui sera configuré à l'aide de ressources de type Ingress.

En utilisant la documentation officielle [https://kubernetes.github.io/ingress-nginx/deploy/](https://kubernetes.github.io/ingress-nginx/deploy/) installez le Ingress Controller qui correspond à votre environnement.

Ensuite, utilisez la commande suivante et attendez que les différents Pods soient correctement démarrés:

:warning: attention cette commande ne vous rendra pas la main, vous pourrez la stopper (avec un CTRL-C) dès que le Pod *ingress-nginx-controller-xxx* présentera *1/1* dans la colonne *READY* et *Running* dans la colonne *STATUS*:

```
kubectl get pods -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx --watch
```

Dans les exercices suivants vous créerez des ressources de type *Ingress* afin de configurer ce Ingress Controller.

Note: si votre cluster tourne chez *Exoscale*, il y a actuellement une issue qui empêche que le service de type Load Balancer soit créé correctement. En attendant que la Pull Request [https://github.com/kubernetes/ingress-nginx/pull/8365](https://github.com/kubernetes/ingress-nginx/pull/8365) corrige le problème, vous pouvez utilisez la commande suivante afin de supprimer l'annotation à l'origine du problème:

```
kubectl -n ingress-nginx annotate svc ingress-nginx-controller service.beta.kubernetes.io/exoscale-loadbalancer-name-
```